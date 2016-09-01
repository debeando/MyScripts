#!/bin/bash
# encoding: UTF-8

wget --quiet -O /tmp/world.sql.gz http://downloads.mysql.com/docs/world.sql.gz
gunzip --quiet /tmp/world.sql.gz

mysql < /tmp/world.sql
