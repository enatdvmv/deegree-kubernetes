#

Deegree im Kubernetes Cluster
=============================

## Inhalt
* [Einleitung](#einleitung)
* [Deegree Workspace](#deegree-workspace)
* [kubectl Namespace](#kubectl-namespace)
* [kubectl Content](#kubectl-content)
* [Summary](#summary)


## Einleitung
Im Repository [deegree-docker](https://github.com/enatdvmv/deegree-docker) haben wir uns damit beschäftigt, wie wir deegree in einem Docker Container bereitstellen. Jetzt gehen wir einen Schritt weiter. Dabei wird das Docker-Image über eine Jenkins-Pipeline gebaut, in einem Artifactory gespeichert und die Container werden in einem Kubernetes-Cluster ausgeführt. Wir konzentrieren uns hier auf den letzten Teil, wie wir deegree in einem Kubernetes-Cluster zum Laufen bringen.


## Deegree Workspace
Dazu müssen wir uns zunächst Gedanken darübermachen, wie wir den deegree Workspace in den Pods zugänglich machen und Datenbank Username/Passwort setzen. Wir behalten im Hinterkopf, das die deegree Dienste im Kubernetes Cluster nicht bearbeitet werden. Das erfolgt ausschließlich lokal. Nach einem Git-Commit wird die Jenkins-Pipeline aktiviert und es steht ein neues Image für den InitialContainer bereit.

Der deegree Workspace wird dazu im [Dockerfile](Dockerfile) aus dem Docker-Context in einen InitContainer kopiert. Im Kubernetes [Deployment](kubernetes/deegree3-deployment.yml) wird ein *emptyDir* gemountet und Kubernetes angewiesen, den Workspace aus dem InitContainer in dieses Volume zu kopieren, welches anschließend auch auf den MainContainer gemountet wird *(vgl. Abb. 1)*. Jeder Pod verfügt über dieses Volume, welches an die Lebenszeit des Pods geknüpft ist.

Username und Passwort werden in einem Secret gespeichert *(base64)*. Wie kommen diese nun in das jdbc-Konfigurationsfile im deegree Workspace? Dazu legen wir 2 Umgebungsvariablen an und verknüpfen sie mit dem Secret. Deegree interpretiert diese aber beim Lesen des jdbc-Konfigurationsfiles nicht. Deshalb weisen wir Kubernetes im [Deployment](kubernetes/deegree3-deployment.yml) an, im Lifecycle postStart, die Werte mit dem Shell Kommando *sed -i* zu setzen. Beide Probleme haben wir damit gelöst.

Es ist noch darauf hinzuweisen, dass wir rekursiv, sämtliche XSD-Schemata lokal im deegree Workspace unter *appschemas* vorhalten müssen, da aus den Pods kein http/https Zugriff auf die Schemata möglich ist.


## kubectl Namespace
Zunächst legen wir uns einen Namespace *deegree* an.
```
kubectl get namespaces
kubectl apply -f D:\kubernetes\deegree3-namespace.yml
```
Schauen uns die Konfiguration an.
```
kubectl config view
kubectl config current-context
```
Definieren den neuen Kontext für kubectl und wechseln in diesen Namespace.
```
kubectl config set-context deegree --namespace=deegree --cluster=myClusterName --user=myUserName
kubectl config use-context deegree
kubectl config current-context
```


## kubectl Content
Wir legen im Namespace *deegree* ein Secret, ein Deployment mit 2 Replicas, ein Service sowie ein Ingress an *(vgl. Abb. 1)*.
```
kubectl apply -f D:\kubernetes\deegree3-secret.yml
kubectl apply -f D:\kubernetes\deegree3-deployment.yml
kubectl apply -f D:\kubernetes\deegree3-service.yml
kubectl apply -f D:\kubernetes\deegree3-ingress.yml
```

Abb. 1: deegree im Kubernetes Cluster
![kubernetes.jpg](img/kubernetes.jpg)

Inspizieren unsere neuen Objekte.
```
kubectl get secret deegree3-secret -o yaml
kubectl get pods
kubectl get services
kubectl get ing
```
Sehen uns in den Pods um.
```
kubectl exec -it myPodName -- /bin/sh
cd /root/.deegree
ls -l
exit

kubectl logs myPodName
```
Testen ob die Pods arbeiten.
URL: http://localhost:8080/deegree-webservices/console/webservices/index.xhtml
```
kubectl port-forward myPodName 8080:8080
```
Testen den Service, ebenfalls auf localhost:8080.
```
kubectl port-forward service/deegree3-service 8080:8080
```
Und schauen ob die deegree Konsole auch von außerhalb des Kubernetes Clusters angesprochen werden kann. Dazu verwenden wir die Address aus dem Ingress.
URL: http://myHost/deegree-webservices/console/webservices/index.xhtml

Und testen die beiden deegree Web-Services (WMS und WFS) in QGIS. Bzw. den WFS über einen GetFeature-Request.
URL: http://myHost/deegree-webservices/services/inspire_us_schulstandorte_download?service=WFS&version=2.0.0&request=GetFeature&typeName=us-govserv:GovernmentalService&Count=10

Für den produktiven Betrieb der deegree WebServices benötigen wir noch 3 weitere Dateien *(main.xml, context.xml, rewrite.config)*, die beispielsweise über configMaps bereitgestellt werden könnten.

Den *DEEGREE_WORKSPACE_ROOT* für den MainContainer setzen wir auf */var/lib/tomcat/.deegree* und arbeiten als *tomcat* User, d.h. ohne *root* Zugriff.


## Summary
In diesem Repository haben wir einen Lösungsweg aufgezeigt, wie deegree WebServices in einem Kubernetes-Cluster betrieben werden können.
