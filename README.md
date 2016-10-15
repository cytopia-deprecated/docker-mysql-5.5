# MySQL 5.5 Docker

[![](https://images.microbadger.com/badges/version/cytopia/mysql-5.5.svg)](https://microbadger.com/images/cytopia/mysql-5.5 "mysql-5.5") [![](https://images.microbadger.com/badges/image/cytopia/mysql-5.5.svg)](https://microbadger.com/images/cytopia/mysql-5.5 "mysql-5.5") [![](https://images.microbadger.com/badges/license/cytopia/mysql-5.5.svg)](https://microbadger.com/images/cytopia/mysql-5.5 "mysql-5.5")

[![cytopia/mysql-5.5](http://dockeri.co/image/cytopia/mysql-5.5)](https://hub.docker.com/r/cytopia/mysql-5.5/)

----

MySQL 5.5 Docker on CentOS 7


----

## Usage

```shell
$ docker run -i -e MYSQL_ROOT_PASSWORD=my-secret-pw -t cytopia/mysql-5.5
```

## Options


### Environmental variables

#### Required environmental variables

| Variable | Type | Description |
|----------|------|-------------|
| MYSQL_ROOT_PASSWORD | string | MySQL root user password of either existing database or in case it does not exist it will initialize the new database with the given password. |

#### Optional environmental variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | `0` | Show shell commands executed during start.<br/>Value: `0` or `1` |
| TIMEZONE | string | `UTC` | Set docker OS timezone.<br/>Example: `Europe/Berlin` |
| MYSQL_SOCKET_DIR | string | `/var/sock/mysqld` | Path inside the docker to the socket directory.<br/><br/>Used to separate socket directory from data directory in order to mount it to the docker host or other docker containers. |
| MYSQL_GENERAL_LOG | bool | `0` | Turn on or off general logging<br/>Corresponds to mysql config: `general-log`<br/>Value: `0` or `1` |



### Default mount points

| Docker | Description |
|--------|-------------|
| /var/lib/mysql | MySQL data dir |
| /var/log/mysql | MySQL log dir |
| /var/sock/mysqld | MySQL socket dir |
| /etc/mysql/conf.d | MySQL configuration directory (used to overwrite MySQL config) |


### Default ports

| Docker | Description |
|--------|-------------|
| 3306   | MySQL listening Port |


## MySQL Configuration

Configuration files inside this docker are read in the following order:

1. /etc/my.cnf
2. /etc/mysql/my.cnf
3. /etc/mysql/docker-default.d/*.cnf
4. /etc/mysql/conf.d/*.cnf


* `/etc/my.cnf` and `/etc/mysql/my.cnf` are operating system defaults.
* `/etc/mysql/docker-default.d/*.cnf` provides defaults via this dockers optional environmental variables (`socket` and `general_log`)
* `/etc/mysql/conf.d/` can be mounted to provide custom `*.cnf` files which can overwrite anything.
