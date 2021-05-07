#!/usr/bin/env bash
#Jumpserver Add Host By:liuwei Mail:al6008@163.com
#/bin/bash /opt/config/soft/add_host.sh "资源分组" 主机名称 ip地址 端口
#/bin/bash /opt/config/soft/add_host.sh "IDC/北京/房山/物理服务器" computel001 172.16.155.161 65535

#JMSAPI地址
export Jms_Url=JMS_URL
export JMS_User=${JMS_USER:-"devops"}
export JMS_Pass=CrdWSY8XtFRJ8dMjNyk4bAVg5LFIhmkR

#超级管理员UUID
export Admin_User=${ADMIN_USER:-"1cdffecb-25b0-4758-b2a2-4b736f082945"}
#Token信息
export Token=${TOKEN:-"$(curl -sfkL -X POST ${Jms_Url}/api/v1/authentication/auth/ -H 'Content-Type: application/json' -d "{\"username\": \"${JMS_User}\", \"password\": \"${JMS_Pass}\"}"|awk -F '"' '{print $4}')"}
#JMS资产机器分组
export Host_Group=${1:-"IDC/北京/房山/物理服务器"}
#JMS资产机器名称
export ASSETS_NAME=${2:-"computel001"}
#JMS资产机器IP地址
export SSH_IP=${3:-"172.16.155.161"}
#JMS资产机器SSH端口
export SSH_PORT=${4:-"22"}

#节点信息
export Node_UUID=$(curl -sfkL -X GET "${Jms_Url}/api/v1/assets/nodes/tree/"  \
   -H  "accept: application/json" \
   -H  "Content-Type: application/json"  \
   -H "Authorization: Bearer ${Token}" \
|python -m json.tool |grep -C 3 '"name": "Default"' |grep 'id' |awk '{print $2}' |tr -d '",')

echo ------------------------------------------添加信息------------------------------------------
echo export Token=${Token}
echo export Node_UUID=${Node_UUID}
echo 分组信息: ${Host_Group}
echo 主机名称: ${ASSETS_NAME}-$(echo ${SSH_IP}|tr '.' '-')
echo 连接信息: ${SSH_IP}:${SSH_PORT}
echo -------------------------------------------------------------------------------------------
#是否继续
test ! -z $5 &&export continue_yes=Y
if [ -z ${continue_yes} ];then
    read -t 15 -p "    输入(Y/y)继续:" continue
else
    continue=Y
fi
if [[ "$(echo ${continue}|tr 'A-Z' 'a-z')" != 'y' ]];then exit 1; fi
echo -----------------------------------------------------------------------------------------
curl  -sfkL -X POST "${Jms_Url}/api/v1/assets/assets/"  \
    -H  "accept: application/json" \
    -H  "Content-Type: application/json" \
    -H "Authorization: Bearer ${Token}" -d \
"{
    \"hostname\": \"${ASSETS_NAME}-$(echo ${SSH_IP}|tr '.' '-')\",
    \"ip\": \"${SSH_IP}\",
    \"protocols\": [
        \"ssh/${SSH_PORT:-"22"}\"
    ],
    \"public_ip\": \"\",
    \"nodes\":[\"${Node_UUID}\"],
    \"admin_user\": \"${Admin_User}\",
    \"platform\": \"Linux\",
    \"nodes_display\": [
        \"/Default/${Host_Group}\"
    ]
}" |python -m json.tool
echo -----------------------------------------------------------------------------------------
echo "/bin/bash $0 $* " >> $0.log;
exit 0
