FROM ubuntu:20.04
MAINTAINER Pavel Loginov (https://github.com/Aidaho12/haproxy-wi) 
MAINTAINER Vladimir Gorkov (gorkov@ya.ru)

ENV TZ=Asia/Barnaul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_LOG_DIR /var/log/apache2

RUN apt update -y \
  && apt upgrade -y \
  && apt install -y apache2 

RUN mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR

RUN apt install git net-tools lshw dos2unix apache2 libapache2-mod-wsgi-py3 \
python3-pip g++ freetype2-demos libatlas-base-dev apache2-ssl-dev netcat python3 \
python3-ldap libpq-dev python3-dev libpython2-dev pkg-config libxml2-dev libxslt1-dev libldap2-dev rsyslog libpq-dev python3-matplotlib python-configparser \
libsasl2-dev libffi-dev libssl-dev gcc rsync ansible  -y


RUN pip3 install paramiko pytz requests pyTelegramBotAPI \
  networkx future jinja2 bottle

RUN git clone https://github.com/Aidaho12/haproxy-wi.git /var/www/haproxy-wi
COPY haproxy-wi.conf /etc/apache2/sites-available/
RUN chown -R www-data:www-data /var/www/haproxy-wi && \
    chown -R www-data:www-data /var/log/apache2 && \
    chmod -R +x /var/www/haproxy-wi/app/*.py && \
    #chmod -R 777 /var/www/haproxy-wi/app && \ 
    a2ensite haproxy-wi.conf && \
    a2enmod cgid && \
    a2enmod ssl


RUN cp /var/www/haproxy-wi/config_other/logrotate/* /etc/logrotate.d/ && \
 mkdir -p  /etc/rsyslog.d && \
 cp /var/www/haproxy-wi/config_other/syslog/* /etc/rsyslog.d && \
 cp /var/www/haproxy-wi/config_other/systemd/* /etc/systemd/system/ && \
 #systemctl daemon-reload && \
 #service rsyslogd restart  && \
 #service metrics_haproxy.service restart  && \
 #service checker_haproxy.service restart  && \
 #service keep_alive.service restart  && \
 #service metrics_haproxy.service enable  && \
 #service checker_haproxy.service enable  && \
 #service keep_alive.service enable  && \
 mkdir -p /var/www/haproxy-wi/app/certs && \
 mkdir -p /var/www/haproxy-wi/keys && \
 mkdir -p /var/www/haproxy-wi/configs/ && \
 mkdir -p /var/www/haproxy-wi/configs/hap_config/ && \
 mkdir -p /var/www/haproxy-wi/configs/kp_config/ && \
 mkdir -p /var/www/haproxy-wi/configs/nginx_config/ && \
 mkdir -p /var/www/haproxy-wi/log/ 


RUN cd /var/www/haproxy-wi/app && \
  ./create_db.py && \
  chown -R www-data:www-data /var/www/haproxy-wi

# Ansible install
RUN mkdir /usr/share/apache2/.ansible && \
  touch /usr/share/apache2/.ansible_galaxy && \
  mkdir /usr/share/apache2/.ssh && \
  chown www-data:www-data /usr/share/apache2/.* && \
  echo "www-data          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers 

# For debug -)
#RUN apt install mc nano -y

RUN apt clean && \
  rm -rf /var/lib/apt/lists/*
  
EXPOSE 443 

CMD ["apachectl", "-D", "FOREGROUND"]
