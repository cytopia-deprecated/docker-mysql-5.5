##
## MySQL 5.5
##

FROM centos:7
MAINTAINER "cytopia" <cytopia@everythingcli.org>

# Copy scripts
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /

# Copy config
COPY ./config/my.cnf /etc/my.cnf

# Install
RUN /docker-install.sh


# Autostart
ENTRYPOINT ["/docker-entrypoint.sh"]
