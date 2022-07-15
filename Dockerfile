# This file is available under the following license:
# under LGPL 2.1 (LICENSE.TXT) Copyright 2022 ...

FROM alpine

LABEL maintainer="..."

ENV WORKSPACE=deegree_workspace_inspire

RUN addgroup -S tomcat && adduser -G tomcat -D -H -s /bin/bash tomcat
USER tomcat

# copy workspace to /tmp/workspaces/
WORKDIR /tmp/workspaces/

COPY workspaces/${WORKSPACE} ${WORKSPACE}/
COPY workspaces/webapps.properties webapps.properties
COPY workspaces/console.pw console.pw
COPY workspaces/config config/
