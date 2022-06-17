# This file is available under the following license:
# under LGPL 2.1 (LICENSE.TXT) Copyright 2022 ...

FROM alpine

LABEL maintainer="..."

ENV WORKSPACE=deegree_workspace_inspire

# copy workspace to /tmp/workspaces/
RUN cd /tmp && \
    mkdir workspaces
	
WORKDIR /tmp/workspaces/

COPY workspaces/${WORKSPACE} ${WORKSPACE}/
COPY workspaces/webapps.properties webapps.properties