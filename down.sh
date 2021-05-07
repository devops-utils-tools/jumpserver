#!/usr/bin/env bash
export Version=${1:-"v2.6.2"}
mkdir -p /data/docker_Nginx_Consul/WebRoot/jumpserver/${Version}
cd /data/docker_Nginx_Consul/WebRoot/jumpserver/${Version}
curl -O -L -x 172.16.155.248:65521 https://github.com/jumpserver/jumpserver/releases/download/${Version}/jumpserver-${Version}.tar.gz
curl -O -L -x 172.16.155.248:65521 https://github.com/jumpserver/koko/releases/download/${Version}/koko-${Version}-linux-amd64.tar.gz
curl -O -L -x 172.16.155.248:65521 https://github.com/jumpserver/luna/releases/download/${Version}/luna-${Version}.tar.gz
curl -O -L -x 172.16.155.248:65521 https://github.com/jumpserver/lina/releases/download/${Version}/lina-${Version}.tar.gz
curl -O -L -x 172.16.155.248:65521 https://download.jumpserver.org/public/kubectl.tar.gz
curl -O -L -x 172.16.155.248:65521 http://download.jumpserver.org/public/kubectl_aliases.tar.gz
exit 0

