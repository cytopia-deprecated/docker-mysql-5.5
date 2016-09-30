#!/bin/sh -eu

print_headline() {
	_txt="${1}"
	_blue="\033[0;34m"
	_reset="\033[0m"

	printf "${_blue}\n%s\n${_reset}" "--------------------------------------------------------------------------------"
	printf "${_blue}- %s\n${_reset}" "${_txt}"
	printf "${_blue}%s\n\n${_reset}" "--------------------------------------------------------------------------------"
}

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
# MAIN ENTRY POINT
################################################################################


###
### Adding User/Group
###
print_headline "1. Adding User/Group"
# Add user and group first to make sure their IDs get
# assigned consistently, regardless of whatever dependencies get added.
run "groupadd -r mysql"
run "adduser mysql -M -s /sbin/nologin -g mysql"



###
### Adding Repositories
###
print_headline "2. Adding Repository"
run "yum -y install epel-release"
run "rpm -Uvh https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm"
run "yum-config-manager --enable mysql55-community"
run "yum-config-manager --disable mysql56-community"
run "yum-config-manager --disable mysql57-community"


###
### Updating Packages
###
print_headline "3. Updating Packages Manager"
run "yum clean all"
run "yum -y check"
run "yum -y update"



###
### Installing Packages
###
print_headline "4. Installing Packages"
run "yum -y install \
	mysql-community-client \
	mysql-community-common \
	mysql-community-devel \
	mysql-community-embedded \
	mysql-community-libs \
	mysql-community-libs-compat \
	mysql-community-server \
	mysql-community-test
	"

