# jumpserver

### Build

docker build --compress --build-arg VERSION=${VERSION} -t ${IMAGE_TAG} ./

### Start DB
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
   
### start Jumpserver
#Jumpserver 安装
shell '''
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
'''
