# Base Image
FROM centos/systemd

# Maintainer
LABEL maintainer="devops@processmaker.com"
LABEL processmaker-stack="pm4"

WORKDIR /tmp/
## install tools ##
RUN yum -y update && yum install -y wget yum-utils mod_ssl
## install mysql-client ##
RUN yum remove -y mariadb* ; \
    yum localinstall -y https://repo.mysql.com//mysql57-community-release-el7-11.noarch.rpm ; \
    yum install -y mysql-community-client
## install nginx ##
RUN echo -e "[nginx] \nname=nginx repo \nbaseurl=http://nginx.org/packages/rhel/7/\$basearch/ \ngpgcheck=0 \nenabled=1" > /etc/yum.repos.d/nginx.repo ; \
    yum -y update && yum clean all && yum -y install nginx ; \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bk ; \
    wget https://artifacts.processmaker.net/dbintegrations/devops/nginx.conf ; \
    mv /tmp/nginx.conf  /etc/nginx/nginx.conf ; \
    systemctl enable nginx 
## PHP installation ##
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm ; \
    rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm ; \
    yum install yum-utils ; \
    yum-config-manager --enable remi-php74 ; \
    yum install -y php php-curl php-json php-cli php-fpm  php-gd php-mysqlnd php-soap php-mbstring php-ldap php-mcrypt php-xml php-opcache php-bcmath php-imap php-posix php-pecl-zip php-pcov php-pear ; \
## configure php.ini ##
RUN sed -i '/short_open_tag = Off/c; \short_open_tag = On' /etc/php.ini ; \
    sed -i '/post_max_size = 8M/c; \post_max_size = 24M' /etc/php.ini ; \
    sed -i '/upload_max_filesize = 2M/c; \upload_max_filesize = 24M' /etc/php.ini ; \
    sed -i '/;date.timezone =/c; \date.timezone = America/New_York' /etc/php.ini ; \
    sed -i '/expose_php = On/c; \expose_php = Off' /etc/php.ini 
## install opcache ##
RUN sed -i '/opcache.max_accelerated_files=4000/c; \opcache.max_accelerated_files=10000' /etc/php.d/10-opcache.ini ; \
    sed -i '/;opcache.max_wasted_percentage=5/c; \opcache.max_wasted_percentage=5' /etc/php.d/10-opcache.ini ; \
    sed -i '/;opcache.use_cwd=1/c; \opcache.use_cwd=1' /etc/php.d/10-opcache.ini ; \
    sed -i '/;opcache.validate_timestamps=1/c; \opcache.validate_timestamps=1' /etc/php.d/10-opcache.ini ; \
    sed -i '/;opcache.fast_shutdown=0/c; \opcache.fast_shutdown=1' /etc/php.d/10-opcache.ini 
## php-fpm configuration ##
RUN wget https://artifacts.processmaker.net/dbintegrations/devops/php-fpm.conf ; \
    mv -f /tmp/php-fpm.conf /etc/php-fpm.d/processmaker.conf ; \
    systemctl enable php-fpm  
## Install Composer ##
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer 
## NodeJS ##
RUN wget https://rpm.nodesource.com/setup_14.x ; \
    sh setup_14.x ; \
    yum -y install nodejs 
## Install Docker and docker-compose ##
RUN yum remove docker* -y ; \
    yum install -y yum-utils device-mapper-persistent-data lvm2 ; \
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo ; \
    yum install docker-ce docker-ce-cli containerd.io -y ; \
    curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose ; \
    chmod +x /usr/local/bin/docker-compose ; \
    usermod -a -G docker nginx ; \
    systemctl enable docker 
## Install Supervisor ##
RUN yum install -y supervisor ; \
    systemctl enable supervisord ;
## Install jq ##
RUN yum install -y jq ;
## Install ssh client ##
RUN yum install -y openssh-clients ;
##  ·· ""
RUN mkdir -p /var/run/php-fpm

ENTRYPOINT ["/usr/sbin/init"]
# Docker entrypoint
EXPOSE 80 6001
