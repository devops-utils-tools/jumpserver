#!/usr/bin/env bash
#jumpserver backup
source /etc/profile &>/dev/null
cat /opt/jumpserver/config.yml|tr ':' '='|tr -d ' '|sed 's/^/export /g' > /tmp/env.sh
source /tmp/env.sh 

export PGPASSWORD=${DB_PASSWORD}
export Name_Time=$(date +"%Y%m%d_%H%M%S")
mkdir -p /opt/config/backup/${Name_Time}

#备份数据库
if [ "$(echo "${DB_ENGINE}"|tr A-Z a-z)" == "$(echo "postgresql"|tr A-Z a-z)" ];then
    pg_dump --host=${DB_HOST} --port=${DB_PORT} --username=${DB_NAME} ${DB_NAME} > /opt/config/backup/${Name_Time}/postgresql.sql
fi

#备份配置文件
cd /opt/config/
cp -ra soft koko  htpasswd  id_rsa  id_rsa.pub  jumpserver_config.yml  jumpserver_koko.yml  nginx.conf   supervisord.conf  supervisord.dat /opt/config/backup/${Name_Time}/
exit 0
