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

| Variable | Type | Description |
|----------|------|-------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | Show shell commands executed during start.<br/>Value: `0` or `1` |
| TIMEZONE | string | Set docker OS timezone.<br/>(Example: `Europe/Berlin`) |
| MYSQL_SOCKET_DIR | string | Path inside the docker to the socket directory.<br/><br/>Used to separate socket directory from data directory in order to mount it to the docker host or other docker containers. |
| MYSQL_GENERAL_LOG | bool | Corresponds to mysql config: `general-log`<br/>Value: `0` or `1` |
| MYSQL_INNODB_BUFFER_POOL_SIZE | int | Corresponds to mysql config: `innodb-buffer-pool-size` |
| MYSQL_JOIN_BUFFER_SIZE | int | Corresponds to mysql config: `join-buffer-size` |
| MYSQL_SORT_BUFFER_SIZE | int | Corresponds to mysql config: `sort-buffer-size` |
| MYSQL_READ_RND_BUFFER_SIZE | int | Corresponds to mysql config: `read-rnd-buffer-size` |
| MYSQL_SYMBOLIC_LINKS | bool | Corresponds to mysql config: `symbolic-links`<br/>Value: `0` or `1` |
| MYSQL_SQL_MODE | string | Corresponds to mysql config: `sql-mode` |
| MYSQL_INNODB_FORCE_RECOVERY | bool | Corresponds to mysql config: `innodb-force-recovery`<br/>Value: `0` or `1`|
| MYSQL_MODE | integer | Corresponds to mysql config: `mode`<br/><ul><li>0 - Off</li><li>1 - Doesn't crash MySQL when it sees a corrupt page</li><li>2 - Doesn't run background operations</li><li>3 - Doesn't attempt to roll back transactions</li><li>4 - Doesn't calculate stats or apply stored/buffered changes</li><li>5 - Doesn't look at the undo logs during start-up</li><li>6 - Doesn't roll-forward from the redo logs (ib_logfiles) during start-up</li></ul>



### Default mount points

| Docker | Description |
|--------|-------------|
| /var/lib/mysql | MySQL data dir |
| /var/log/mysql | MySQL log dir |
| /var/run/mysqld | MySQL socket dir |

### Default ports

| Docker | Description |
|--------|-------------|
| 3306   | MySQL listening Port |
