#!/bin/sh -eu

###
### Variables
###
DEBUG_COMMANDS=0

DB_USER="mysql"
DB_GROUP="mysql"
DB_CONFIG="/etc/mysql/my.cnf"
DB_CUSTOM_CONFIG="/etc/mysql/conf.d/custom.cnf"


###
### Functions
###
run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"


	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		if [ "${2}" = "1" ]; then
			_debug="1"
		fi
	fi


	if [ "${DEBUG_COMMANDS}" = "1" ] || [ "${_debug}" = "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

log() {
	_lvl="${1}"
	_msg="${2}"

	_clr_ok="\033[0;32m"
	_clr_info="\033[0;34m"
	_clr_warn="\033[0;33m"
	_clr_err="\033[0;31m"
	_clr_rst="\033[0m"

	if [ "${_lvl}" = "ok" ]; then
		printf "${_clr_ok}[OK]   %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "info" ]; then
		printf "${_clr_info}[INFO] %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "warn" ]; then
		printf "${_clr_warn}[WARN] %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	elif [ "${_lvl}" = "err" ]; then
		printf "${_clr_err}[ERR]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	else
		printf "${_clr_err}[???]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	fi
}


###
### Read out MySQL Default config
###
_get_mysql_default_config() {
	_key="${1}"
	mysqld --verbose --help --log-bin-index="$(mktemp -u)" 2>/dev/null | grep "^${_key}" | awk '{ print $2; exit }'
}


###
### Set MySQL Custom options
###
_set_mysql_custom_settings() {
	_mysql_key="${1}"
	_shell_var="${2}"


	if ! set | grep "^${_shell_var}=" >/dev/null 2>&1; then
		_mysql_val="$( _get_mysql_default_config "${_mysql_key}" )"
		log "info" "\$${_shell_var} not set. Keeping default: ${_mysql_key}=${_mysql_val}"

	else
		_shell_val="$( eval "echo \${${_shell_var}}" )"

		if [ "${_shell_val}" = "" ]; then
			_mysql_val="$( _get_mysql_default_config "${_mysql_key}" )"
			log "info" "\$${_shell_var} is empty. ${_mysql_key}=${_mysql_val}"

		else
			log "info" "Setting MySQL: ${_mysql_key}=${_shell_val}"
			run "echo '${_mysql_key} = ${_shell_val}' >> ${DB_CUSTOM_CONFIG}"
		fi
	fi
}




################################################################################
# BOOTSTRAP
################################################################################

if set | grep '^DEBUG_COMPOSE_ENTRYPOINT='  >/dev/null 2>&1; then
	if [ "${DEBUG_COMPOSE_ENTRYPOINT}" = "1" ]; then
		DEBUG_COMMANDS=1
	fi
fi



################################################################################
# ENVIRONMENTAL CHECKS
################################################################################



###
### MySQL Password Options
###
if ! set | grep '^MYSQL_ROOT_PASSWORD=' >/dev/null 2>&1; then
	log "err" "\$MYSQL_ROOT_PASSWORD must be set."
	exit 1
fi


################################################################################
# MAIN ENTRY POINT
################################################################################


###
### Adjust timezone
###

if ! set | grep '^TIMEZONE='  >/dev/null 2>&1; then
	log "warn" "\$TIMEZONE not set."
else
	if [ -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
		# Unix Time
		log "info" "Setting docker timezone to: ${TIMEZONE}"
		run "rm /etc/localtime"
		run "ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
	else
		log "err" "Invalid timezone for \$TIMEZONE."
		log "err" "\$TIMEZONE: '${TIMEZONE}' does not exist."
		exit 1
	fi
fi
log "info" "Docker date set to: $(date)"



###
### Custom MySQL Socket Path
###

# socket
mysql_key="socket"
if ! set | grep '^MYSQL_SOCKET_DIR=' >/dev/null 2>&1; then
	mysql_val="$( _get_mysql_default_config "${mysql_key}" )"
	log "info" "\$MYSQL_SOCKET_DIR not set. Keeping default: ${mysql_key}=${mysql_val}"

elif [ "${MYSQL_SOCKET_DIR}" = "" ]; then
	mysql_val="$( _get_mysql_default_config "${mysql_key}" )"
	log "info" "\$MYSQL_SOCKET_DIR is empty. Keeping default: ${mysql_key}=${mysql_val}"

else
	log "info" "Setting MySQL: ${mysql_key}=${MYSQL_SOCKET_DIR}/mysqld.sock"
	run "sed -i'' 's|^socket.*$|${mysql_key} = ${MYSQL_SOCKET_DIR}/mysqld.sock|g' ${DB_CONFIG}"

	if [ ! -d "${MYSQL_SOCKET_DIR}"  ]; then
		run "mkdir -p ${MYSQL_SOCKET_DIR}"
	fi
	run "chown -R mysql:mysql ${MYSQL_SOCKET_DIR}"
fi



###
### Add custom Configuration
###
run "echo '[mysqld]' > ${DB_CUSTOM_CONFIG}"

# Logging
_set_mysql_custom_settings "general-log" "MYSQL_GENERAL_LOG"

# Performance
_set_mysql_custom_settings "innodb-buffer-pool-size" "MYSQL_INNODB_BUFFER_POOL_SIZE"
_set_mysql_custom_settings "join-buffer-size" "MYSQL_JOIN_BUFFER_SIZE"
_set_mysql_custom_settings "sort-buffer-size" "MYSQL_SORT_BUFFER_SIZE"
_set_mysql_custom_settings "read-rnd-buffer-size" "MYSQL_READ_RND_BUFFER_SIZE"

# Security
_set_mysql_custom_settings "symbolic-links" "MYSQL_SYMBOLIC_LINKS"
_set_mysql_custom_settings "sql-mode" "MYSQL_SQL_MODE"









################################################################################
# INSTALLATION
################################################################################

DB_DATA_DIR="$( _get_mysql_default_config "datadir" )"


##
## INSTALLATION
##
if [ -d "${DB_DATA_DIR}/mysql" ]; then
	log "info" "Found existing data directory. MySQL already setup."

else

	log "info" "No existing MySQL data directory found. Setting up MySQL for the first time."

	# Create datadir if not exist yet
	if [ ! -d "${DB_DATA_DIR}" ]; then
		log "info" "Creating empty data directory in: ${DB_DATA_DIR}."
		run "mkdir -p ${DB_DATA_DIR}"
		run "chown -R ${DB_USER}:${DB_GROUP} ${DB_DATA_DIR}"
	fi


	# Install Database
	run "mysql_install_db --datadir=${DB_DATA_DIR} --user=${DB_USER}"


	# Start server
	run "mysqld --skip-networking &"


	# Wait at max 60 seconds for it to start up
	i=0
	max=60
	while [ $i -lt $max ]; do
		if echo 'SELECT 1' |  mysql --protocol=socket -uroot  > /dev/null 2>&1; then
			break
		fi
		log "info" "Initializing ..."
		sleep 1s
		i=$(( i + 1 ))
	done


	# Get current pid
	pid="$(pgrep mysqld | head -1)"
	if [ "${pid}" = "" ]; then
		log "err" "Could not find running MySQL PID."
		log "err" "MySQL init process failed."
		exit 1
	fi


	# Bootstrap MySQL
	log "info" "Setting up root user permissions."
	echo "DELETE FROM mysql.user ;" | mysql --protocol=socket -uroot
	echo "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;" | mysql --protocol=socket -uroot
	echo "GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;" | mysql --protocol=socket -uroot
	echo "DROP DATABASE IF EXISTS test ;" | mysql --protocol=socket -uroot
	echo "FLUSH PRIVILEGES ;" | mysql --protocol=socket -uroot


	# Shutdown MySQL
	log "info" "Shutting down MySQL."
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


	# Check if it is still running
	if pgrep mysqld >/dev/null 2>&1; then
		log "err" "Unable to shutdown MySQL server."
		log "err" "MySQL init process failed."
		exit 1
	fi
	log "info" "MySQL successfully installed."

fi



###
### Start
###
log "info" "Starting $(mysqld --version)"
run "mysqld" "1"
