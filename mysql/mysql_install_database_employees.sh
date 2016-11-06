#!/bin/bash
# encoding: UTF-8

wget --quiet -O /tmp/employees.zip https://github.com/datacharmer/test_db/archive/master.zip
unzip -qo /tmp/employees.zip -d /tmp/employees/

cd /tmp/employees/test_db-master/ || exit 1
mysql < employees.sql
