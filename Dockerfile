ARG BASE_IMG=python:3.8.10-slim
FROM ${BASE_IMG}
ARG VERSION=v2.9.2
USER root
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
    sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list &&\
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list &&\
    apt update &&\
    apt-get install -y --no-install-recommends --no-install-suggests curl iproute2 netcat tcpdump telnet ca-certificates net-tools locales expect procps inetutils-ping gnutls-bin dnsutils libpq-dev &&\
    apt-get install -y --no-install-recommends --no-install-suggests cron sudo iptables openssh-client openssh-server nginx supervisor redis bash-completion apache2-utils &&\
    mkdir -p /opt/jumpserver /opt/luna /opt/koko /opt/lina &&\
    echo "${VERSION}" > /etc/version.env &&\
    curl -skfL http://172.16.155.248/index.html/jumpserver/${VERSION}/jumpserver-${VERSION}.tar.gz |tar -xzf - -C /opt/jumpserver --strip-components=1  &&\
    curl -skfL http://172.16.155.248/index.html/jumpserver/${VERSION}/luna-${VERSION}.tar.gz |tar -xzf - -C  /opt/luna --strip-components=1  &&\
    curl -skfL http://172.16.155.248/index.html/jumpserver/${VERSION}/lina-${VERSION}.tar.gz |tar -xzf - -C /opt/lina  --strip-components=1 &&\
    curl -skfL http://172.16.155.248/index.html/jumpserver/${VERSION}/koko-${VERSION}-linux-amd64.tar.gz |tar -xzf - -C /opt/koko  --strip-components=1 &&\
    grep -vE "#|^$" /opt/jumpserver/requirements/deb_buster_requirements.txt  | xargs -r apt install --no-install-recommends --no-install-suggests -y  &&\
    mkdir -p /root/.pip/ &&\
    echo  "[global]\nindex-url = http://mirrors.aliyun.com/pypi/simple/\n[install]\ntrusted-host=mirrors.aliyun.com" >/root/.pip/pip.conf &&\
    pip install --upgrade pip==20.2.4 setuptools==49.6.0 wheel==0.34.2 &&\
    pip install incremental==16.10.1 pbr==2.0.0 &&\
    pip install --no-cache-dir $(grep -vE "#" /opt/jumpserver/requirements/requirements.txt) &&\
    pip install psycopg2 &&\
    echo "#By:liuwei Mail:al6008@163.com \n* soft nofile 1048576\n* hard nofile 1048576\n* soft nproc unlimited\n* hard nproc unlimited\n* soft core unlimited\n* hard core unlimited\nroot soft nofile 1048576\nroot hard nofile 1048576\nroot soft nproc unlimited\nroot hard nproc unlimited\nroot soft core unlimited\nroot hard core unlimited" >> /etc/security/limits.conf &&\
    mkdir -p /etc/ansible/ &&\
    echo "[ssh_connection]\ncontrol_path_dir=/dev/shm/ansible_control_path" > /etc/ansible/ansible.cfg &&\
    mkdir -p /root/.ssh/ && echo "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null" > /root/.ssh/config &&\
    curl -o /tmp/kubectl.tar.gz -sfkL http://172.16.155.248/index.html/jumpserver/${VERSION}/kubectl.tar.gz &&\
    tar xf /tmp/kubectl.tar.gz -C /tmp  &&\
    mv /tmp/kubectl /usr/local/bin/rawkubectl  &&\
    chmod 755 /usr/local/bin/rawkubectl  &&\
    chown root:root /usr/local/bin/rawkubectl &&\
    curl -o /tmp/kubectl_aliases.tar.gz -sfkL http://172.16.155.248/index.html/jumpserver/${VERSION}/kubectl_aliases.tar.gz &&\
    mkdir -p /opt/kubectl-aliases/ /opt/config /opt/reids_data /opt/jumpserver /opt/koko /opt/lina /opt/luna &&\
    chmod 700 /opt/reids_data /opt/config /opt/jumpserver /opt/koko &&\
    tar -xf /tmp/kubectl_aliases.tar.gz -C /opt/kubectl-aliases/ &&\
    chown -R root:root /opt/kubectl-aliases/ &&\
    mv /opt/koko/kubectl /usr/local/bin/ &&\
    chmod 755 /opt/koko/init-kubectl.sh &&\
    cp -f /bin/chown /usr/local/chowndir &&\
    chmod +rxs /usr/local/chowndir &&\
    chmod ug+w /usr/local/chowndir &&\
    cd /tmp/ &&\
    apt-get purge -y --auto-remove -y  mariadb* &&\
    curl -sfkL http://172.16.155.248/index.html/jumpserver/dbtools/dbtool.tar.gz |tar -xzf - -C /tmp/ &&\ 
    dpkg --force-depends -i *.deb  &&\
    apt --fix-broken install -f -y --no-install-recommends --no-install-suggests  &&\
    apt-get purge -y --auto-remove gcc cmake  &&\
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false &&\
    apt-get clean all &&\
    localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8 &&\
    cd / &&\
    rm -rf /var/lib/apt/lists/ &&\
    rm -rf /var/cache/* &&\
    rm -rf /tmp/* &&\
    mkdir -p /tmp/workdir/
ENV TZ Asia/Shanghai
ENV LANG zh_CN.UTF-8
VOLUME /opt/jumpserver/data
VOLUME /opt/config
WORKDIR /tmp/workdir/
COPY nginx.conf /etc/nginx/nginx.conf.tmp
COPY entrypoint.sh /sbin/entrypoint.sh
COPY healthcheck.sh /sbin/healthcheck.sh
COPY jms_api /sbin/jms_api
COPY api_init /sbin/api_init
COPY add_host.sh /sbin/add_host.sh
COPY backup.sh /sbin/backup.sh
#EXPOSE 80 2222
HEALTHCHECK --interval=45s --timeout=5s --retries=3 --start-period=150s CMD ["/bin/bash","/sbin/healthcheck.sh"]
ENTRYPOINT ["/bin/bash","/sbin/entrypoint.sh"]
LABEL maintainer="JumpServer ${VERSION} <By:liuwei Mail:al6008@163.com Date:2021-01-20>"

