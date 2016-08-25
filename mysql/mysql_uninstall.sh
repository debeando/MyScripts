#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_uninstall.sh
# Description     :Uninstall MySQL Server.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-06-03
# Version         :0.1
# ==============================================================================

killall mysqld
apt-get remove --purge -y percona\*
apt-get autoremove -y
