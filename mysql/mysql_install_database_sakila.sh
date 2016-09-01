#!/bin/bash
# encoding: UTF-8

wget --quiet -O /tmp/sakila-db.tar.gz http://downloads.mysql.com/docs/sakila-db.tar.gz
tar -zxf /tmp/sakila-db.tar.gz -C /tmp/

mysql < /tmp/sakila-db/sakila-schema.sql
mysql < /tmp/sakila-db/sakila-data.sql
