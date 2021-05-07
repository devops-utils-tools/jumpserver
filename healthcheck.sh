#!/usr/bin/env bash
#jumpserver healthcheck By:liuwei Mail:al6008@163.com
source /etc/profile &>/dev/null

#启动失败服务
supervisorctl status |grep FATAL |awk '{print $1}' |xargs -r -i supervisorctl start {}

#运行检查
test -f /tmp/jumpserver.run||exit 0

#url检查
set -eo pipefail
if [ -e /usr/bin/curl ];then
    /usr/bin/curl -k -s -L -I http://127.0.0.1:8080 &>/dev/null &&\
    /usr/bin/curl -k -s -L -I http://127.0.0.1:8070 &>/dev/null &&\
    /usr/bin/curl -k -s -L -I http://127.0.0.1:80 &>/dev/null &&\
    /usr/bin/curl -k -s -L -I http://127.0.0.1:5555 &>/dev/null &&\
    /usr/bin/curl -k -s -L -I 127.0.0.1:5000 &>/dev/null || exit 1
    exit 0
fi
exit 1
