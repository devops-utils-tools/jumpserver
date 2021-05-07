### Build
```
docker build --compress --build-arg VERSION=${VERSION} -t ${IMAGE_TAG} ./
```
### Start DB
```
export Node_Name=PostGreSQL-9.6.16
export Data_Path=/data/docker_${Node_Name}
export MEMORY_SIZE=2048
export IMAGE_TAG=postgres:9.6.16

docker rm -f Jumpserver PostGreSQL-9.6.16
rm -rf /data/docker_Jumpserver/

docker stop ${Node_Name} &>/dev/null
docker rm -f ${Node_Name} &>/dev/null

test ! -z ${Data_Path}&&test -e ${Data_Path}&&rm -rf ${Data_Path}
mkdir -p ${Data_Path}/ &&chown -R 1000:1000 ${Data_Path}

docker run -d --name ${Node_Name} --hostname ${Node_Name} \
    --restart always --oom-kill-disable \
    --memory ${MEMORY_SIZE}M \
    -p 5432:5432 \
    -e TZ="Asia/Shanghai" \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=Postgres_Sql_Admin_By_liuwei_Al6008@163.com \
    -e POSTGRES_DB=postgres \
    -v ${Data_Path}/:/var/lib/postgresql/data \
${IMAGE_TAG} \
   -c 'shared_buffers=256MB' \
   -c 'max_connections=512'
```

### Start Jumpserver
```
export Node_Name=Jumpserver
export Data_Path=/data/docker_${Node_Name}
export MEMORY_SIZE=4096
export IMAGE_TAG=devopsutilstools/jumpserver:v2.9.2

docker stop ${Node_Name} &>/dev/null
docker rm -f ${Node_Name} &>/dev/null
test ! -z ${Data_Path}&&test -e ${Data_Path}&&rm -rf ${Data_Path}

docker run -d --name ${Node_Name} --hostname ${Node_Name} \
    --restart always --oom-kill-disable \
    --memory ${MEMORY_SIZE}M \
    -p 8080:80 \
    -p 62212:2222 \
    --privileged \
    -e SSH_KEY_SIZE=1024 \
    -e JMS_URL="http://172.16.155.219:8080" \
    -e GUCAMOLE_URL="192.168.0.193:51081" \
    -e DB_ENGINE="postgresql" \
    -e DB_HOST="172.16.155.219" \
    -e DB_USER="postgres" \
    -e DB_PASSWORD="Postgres_Sql_Admin_By_liuwei_Al6008@163.com" \
    -e DB_NAME="postgres" \
    -v ${Data_Path}/config:/opt/config/ \
    -v ${Data_Path}/data:/opt/jumpserver/data/ \
${IMAGE_TAG}

docker logs --tail 30 -f ${Node_Name}
```
### 等待服务完全启动成功 第一次启动 5分钟左右
```
docker exec -it Jumpserver /bin/bash -c "supervisorctl status"
```

### 打开网页
```
http://IP:8080 账号密码 (docker exec -it Jumpserver /bin/bash -c "/opt/config/supervisord.dat")
```

### 快速添加主机 
```
docker exec -it Jumpserver /bin/bash -c "/bin/bash /opt/config/soft/add_host.sh 资源分组 主机名称 ip地址 端口"
```

### 配置说明
```
SSH_KEY base64 ssh私钥(cat /root/.ssh/id_rsa |base64 |tr -d '\n')
SSH_KEY_SIZE ssh私钥size
JMS_URL jumpserver外网地址 api添加主机使用
GUCAMOLE_URL VNC远程
DB_* 数据库配置
```
