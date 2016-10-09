##
## MySQL 5.5
##
FROM centos:7
MAINTAINER "cytopia" <cytopia@everythingcli.org>


##
## Bootstrap Scipts
##
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /


##
## Install
##
RUN /docker-install.sh


##
## Ports
##
EXPOSE 3306


##
## Volumes
##
VOLUME /var/lib/mysql
VOLUME /var/log/mysql
VOLUME /var/run/mysqld


##
## Entrypoint
##
ENTRYPOINT ["/docker-entrypoint.sh"]
