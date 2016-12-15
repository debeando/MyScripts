#!/usr/bin/python
# -*- coding: utf8 -*-
# ======================================================================
# License: GPL License (see COPYING)
# Copyright 2013 PalominoDB Inc.
# ======================================================================

from optparse import OptionParser
import sys
import os
from decimal import *
import MySQLdb.cursors

def fetch_all(host, user, password='', port='' ):
  "Get schema information"
  try:
    conn = MySQLdb.connect(host=host, user=user, passwd=password, port=port, db='information_schema', cursorclass=MySQLdb.cursors.DictCursor)
    cursor = conn.cursor()
    cursor.execute("SELECT table_schema, table_name, column_name, column_type, column_key FROM columns WHERE table_schema NOT IN ('information_schema', 'mysql', 'percona') AND column_type LIKE '%int%';")
    rows = cursor.fetchall()
    cursor.close()
  except Exception, err:
    print "UNKNOWN: - Unable to connect to: "+ host, sys.exc_info()[0]
    print result
    sys.exit(3)
  return rows


def find_max(host, user, password='', port='', col=None, t_schema=None, t_name=None ):
  "Find the column with maximum value"
  try:
    conn = MySQLdb.connect(host=host, user=user, passwd=password, port=port, db=t_schema, cursorclass=MySQLdb.cursors.DictCursor)
    cursor = conn.cursor()
    cursor.execute("SELECT max(%s) AS value FROM %s" % (col, t_name))
    row = cursor.fetchone()['value']
    cursor.close()
  except Exception, err:
    print "UNKNOWN: - Unable to connect to: "+ host, sys.exc_info()[0]
    sys.exit(3)
  return row


if __name__ == "__main__":
  #Arguments
  usage = 'Usage: %prog [options] arg1 arg2'
  parser = OptionParser(usage = usage)
  parser.add_option('-H', '--host', dest = 'host', help = 'Database host')
  parser.add_option('-u', '--user', dest = 'user', help = 'Database username')
  parser.add_option('-p', '--password', dest = 'password', help = 'Database Password')
  parser.add_option('-P', '--port', dest = 'port', help = 'Database port')
  parser.add_option('-w', '--warning', dest = 'warning', help = 'Warning threshold is the % between current connections and max connections (int).')
  parser.add_option('-c', '--critical', dest = 'critical', help = 'Critical threshhold is the % between current connections and max connections (int).')
  (options,args) = parser.parse_args()

  host = options.host
  user = options.user
  passwd = options.password
  port = options.port
  warning = int(options.warning)
  critical = int(options.critical)

  # Sanity check. Ugly but there is a bug which has not allow to define a default int value on funcion definition.
  if not port:
    port = 3306
  else:
    port=int(port)

  getcontext().prec = 10
  tinyint = 127
  smallint = 32767
  mediumint = 8388607
  int = 2147483647
  bigint = 9223372036854775807

  tinyint_us = 255
  smallint_us = 65535
  mediumint_us = 16777215
  int_us = 4294967295
  bigint_us = 18446744073709551615


  rows = fetch_all(host, user, passwd, port)
  for row in rows:
    schema = row['table_schema']
    table = row['table_name']
    column = row['column_name']
    column_type = row['column_type']
    column_key = row['column_key']
    if column_key and column_key == 'PRI':
      max_int = find_max(host, user, passwd, port, column,schema,table)

      if max_int is None:
        max_int = 0

      unsigned = False
      if 'unsigned' in column_type:
         unsigned = True

      # Clean up column_type information
      int_type = column_type.split('(')[0]


      of_pct = 0
      if not unsigned:
        if int_type == "tinyint": of_pct = (Decimal(max_int)/Decimal(tinyint))*100
        elif int_type == "smallint": of_pct = (Decimal(max_int)/Decimal(smallint))*100
        elif int_type == "mediumint": of_pct = (Decimal(max_int)/Decimal(mediumint))*100
        elif int_type == "int": of_pct = (Decimal(max_int)/Decimal(int))*100
        elif int_type == "bigint": of_pct = (Decimal(max_int)/Decimal(bigint))*100
        else: of_pct = 0

      else:
        if int_type == "tinyint": of_pct = (Decimal(max_int)/Decimal(tinyint_us))*100
        elif int_type == "smallint": of_pct = (Decimal(max_int)/Decimal(smallint_us))*100
        elif int_type == "mediumint": of_pct = (Decimal(max_int)/Decimal(mediumint_us))*100
        elif int_type == "int": of_pct = (Decimal(max_int)/Decimal(int_us))*100
        elif int_type == "bigint": of_pct = (Decimal(max_int)/Decimal(bigint_us))*100
        else: of_pct = 0

      print "On Database: %s Table: %s Row: %s the percentage used is: %.2f %%" % (schema, table, column, of_pct)
