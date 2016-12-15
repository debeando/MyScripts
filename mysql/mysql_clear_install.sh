#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_clear_install.sh
# Description     :Clear MySQL instalation
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2014-08-10
# Version         :0.2
# ==============================================================================

# Kill All process for MySQL:
killall -9 mysqld_safe
killall -9 mysqld

# Empry pid file for MySQL:
truncate -s 0 /var/run/mysqld/mysqld.pid

# Remove old MySQL Data Directory:
rm -rf /var/lib/mysql/*

# Initialize MySQL Data Directory:
mysql_install_db --user=mysql --datadir=/var/lib/mysql

chown -R mysql. /var/lib/mysql
