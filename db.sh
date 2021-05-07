#PostGreSQL 安装
export Node_Name=PostGreSQL-9.6.16
#export Data_Path=${HOME}/data/docker_${Node_Name}
export Data_Path=/data/docker_${Node_Name}
export MEMORY_SIZE=2048
#export IMAGE_TAG=jenkins/jenkins:lts
export IMAGE_TAG=postgres:9.6.16
#docker pull ${IMAGE_TAG}



docker rm -f Jumpserver PostGreSQL-9.6.16
rm -rf /data/docker_Jumpserver/



docker stop ${Node_Name} &>/dev/null
docker rm -f ${Node_Name} &>/dev/null

#docker volume create --name ${Node_Name}
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
#    --user root \
#    --network host
