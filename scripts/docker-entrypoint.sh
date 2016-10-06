#!/bin/sh -eu

##
## VARIABLES
##
DB_USER="mysql"
DB_GROUP="mysql"
DB_CONFIG="/etc/mysql/my.cnf"


##
## FUNCTIONS
##
run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


################################################################################
# ENVIRONMENTAL CHECKS
################################################################################



##
## MySQL Password Options
##
if ! set | grep '^MYSQL_ROOT_PASSWORD=' >/dev/null 2>&1; then
	echo >&2 "\$MYSQL_ROOT_PASSWORD must be set."
	exit 1
fi

##
## Custom settings (supplied via Docker env variables)
##
if set | grep '^MYSQL_SOCKET_DIR=' >/dev/null 2>&1; then
	run "sed -i'' 's|^socket.*$|socket = ${MYSQL_SOCKET_DIR}/mysqld.sock|g' ${DB_CONFIG}"
	if [ ! -d "${MYSQL_SOCKET_DIR}"  ]; then run "mkdir -p ${MYSQL_SOCKET_DIR}" ; fi
	run "chown -R mysql:mysql ${MYSQL_SOCKET_DIR}"
fi


##
## More Custom settings
##
run "echo '[mysqld]' > /etc/mysql/conf.d/custom.cnf"

# Logging
if set | grep '^MYSQL_GENERAL_LOG=' >/dev/null 2>&1; then
	if [ "${MYSQL_GENERAL_LOG}" != "" ]; then
		run "echo 'general_log = ${MYSQL_GENERAL_LOG}' >> /etc/mysql/conf.d/custom.cnf"
	fi
fi

# Performance
if set | grep '^MYSQL_INNODB_BUFFER_POOL_SIZE=' >/dev/null 2>&1; then
	if [ "${MYSQL_INNODB_BUFFER_POOL_SIZE}" != "" ]; then
		run "echo 'innodb_buffer_pool_size = ${MYSQL_INNODB_BUFFER_POOL_SIZE}' >> /etc/mysql/conf.d/custom.cnf"
	fi
fi
if set | grep '^MYSQL_JOIN_BUFFER_SIZE=' >/dev/null 2>&1; then
	if [ "${MYSQL_JOIN_BUFFER_SIZE}" != "" ]; then
		run "echo 'join_buffer_size = ${MYSQL_JOIN_BUFFER_SIZE}' >> /etc/mysql/conf.d/custom.cnf"
	fi
fi
if set | grep '^MYSQL_SORT_BUFFER_SIZE=' >/dev/null 2>&1; then
	if [ "${MYSQL_SORT_BUFFER_SIZE}" != "" ]; then
		run "echo 'sort_buffer_size = ${MYSQL_SORT_BUFFER_SIZE}' >> /etc/mysql/conf.d/custom.cnf"
	fi
fi
if set | grep '^MYSQL_READ_RND_BUFFER_SIZE=' >/dev/null 2>&1; then
	if [ "${MYSQL_READ_RND_BUFFER_SIZE}" != "" ]; then
		run "echo 'read_rnd_buffer_size = ${MYSQL_READ_RND_BUFFER_SIZE}' >> /etc/mysql/conf.d/custom.cnf"
	fi
fi

# Security
if set | grep '^MYSQL_SYMBOLIC_LINKS=' >/dev/null 2>&1; then
	if [ "${MYSQL_SYMBOLIC_LINKS}" != "" ]; then
		run "echo 'symbolic-links = ${MYSQL_SYMBOLIC_LINKS}' >> /etc/mysql/conf.d/custom.cnf"
	fi
fi
if set | grep '^MYSQL_SQL_MODE=' >/dev/null 2>&1; then
	if [ "${MYSQL_SQL_MODE}" != "" ]; then
		run "echo 'sql_mode = ${MYSQL_SQL_MODE}' >> /etc/mysql/conf.d/custom.cnf"
	fi
fi





##
## MySQL 5.5 specific version to
## find out the data directory
##
_datadir() {
	mysqld --verbose --help --log-bin-index="$(mktemp -u)" 2>/dev/null | awk '$1 == "datadir" { print $2; exit }'
}


################################################################################
# MAIN ENTRY POINT
################################################################################

DB_DATA_DIR="$(_datadir)"


##
## INSTALLATION
##
if [ ! -d "${DB_DATA_DIR}/mysql" ]; then

	# Create datadir if not exist yet
	if [ ! -d "${DB_DATA_DIR}" ]; then
		run "mkdir -p ${DB_DATA_DIR}"
		run "chown -R ${DB_USER}:${DB_GROUP} ${DB_DATA_DIR}"
	fi

	#run "mysql_install_db --user=${DB_USER}"
	run "mysql_install_db --datadir=${DB_DATA_DIR} --user=${DB_USER}"


	# Start server
	run "mysqld --skip-networking &"


	# Wait for it to finish
	i=0
	max=60
	while [ $i -lt $max ]; do
		if echo 'SELECT 1' |  mysql --protocol=socket -uroot  > /dev/null 2>&1; then
			break
		fi
		echo 'MySQL init process in progress...'
		sleep 1s
		i=$(( i + 1 ))
	done


	# Get current pid
	pid="$(pgrep mysqld | head -1)"
	if [ "${pid}" = "" ]; then
		echo >&2  "MySQL init process failed..."
		exit 1
	fi


	# Bootstrap MySQL
	echo "DELETE FROM mysql.user ;" | mysql --protocol=socket -uroot
	echo "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;" | mysql --protocol=socket -uroot
	echo "GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;" | mysql --protocol=socket -uroot
	echo "DROP DATABASE IF EXISTS test ;" | mysql --protocol=socket -uroot
	echo "FLUSH PRIVILEGES ;" | mysql --protocol=socket -uroot


	# Shutdown MySQL
	kill -s TERM "$pid"
	i=0
	max=60
	while [ $i -lt $max ]; do
		if ! pgrep mysqld >/dev/null 2>&1; then
			break
		fi
		sleep 1s
		i=$(( i + 1 ))
	done

	echo
	echo 'MySQL init process done. Ready for start up.'
	echo

else
	echo
	echo 'MySQL found existing data directory. Ready for start up.'
	echo
fi

run "hostname -I"
run "mysqld --version"
run "mysqld"
