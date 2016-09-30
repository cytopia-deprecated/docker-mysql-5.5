#!/bin/sh -eu

##
## VARIABLES
##
DB_USER="mysql"
DB_GROUP="mysql"


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


run "mysqld"
