#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

import pymysql
import pymysql.cursors
import terminaltables

class Connections:
  def __init__(self, memory):
    self.memory = memory;

class Collector:
  def __init__(self, host, port, user, password):
    variables = query("SHOW VARIABLES");

  def get_variable(cur, name):
    for row in cur:
      if row['Variable_name'] == name:
        return int(row['Value'])
    return 0

  def get_status(cur, name):
    for row in cur:
      if row['Variable_name'] == name:
        return int(row['Value'])
    return 0

  def query(sql):
    cur = conn.cursor()
    cur.execute("SHOW VARIABLES")
    result = cur.fetchall()
    cur.close()
    return result



exit(0)

# Connect to the database
conn = pymysql.connect(host='localhost',
                       port=3307,
                       user='nstrappazzon',
                       password='GHa6S5vCdadnsB72Be34c7y6a',
                       db='',
                       charset='utf8mb4',
                       cursorclass=pymysql.cursors.DictCursor)

cur = conn.cursor()
cur.execute("SHOW VARIABLES")
variables = cur.fetchall()
cur.close()

cur = conn.cursor()
cur.execute("SHOW STATUS")
status = cur.fetchall()
cur.close()

conn.close()

#for row in cur:
#  print(" - %s: %s" % (row['Variable_name'], row['Value']))


memory = 21;

global_buffers = {
  'innodb_buffer_pool_size':         get_variable(variables, 'innodb_buffer_pool_size'),
  'innodb_log_buffer_size':          get_variable(variables, 'innodb_log_buffer_size'),
  'innodb_additional_mem_pool_size': get_variable(variables, 'innodb_additional_mem_pool_size'),
  'net_buffer_length':               get_variable(variables, 'net_buffer_length'),
  'key_buffer_size':                 get_variable(variables, 'key_buffer_size'),
  'query_cache_size':                get_variable(variables, 'query_cache_size'),
}

thread_buffers = {
  'sort_buffer_size':        get_variable(variables, 'sort_buffer_size'),
  'thread_stack':            get_variable(variables, 'thread_stack'),
  'join_buffer_size':        get_variable(variables, 'join_buffer_size'),
  'read_buffer_size':        get_variable(variables, 'read_buffer_size'),
  'read_rnd_buffer_size':    get_variable(variables, 'read_rnd_buffer_size'),
  'myisam_sort_buffer_size': get_variable(variables, 'myisam_sort_buffer_size'),
}

global_buffers_sum = sum(global_buffers.values());
thread_buffers_sum = sum(thread_buffers.values());

max_connections_set  = get_variable(variables, 'max_connections');
max_used_connections = get_status(status, 'Max_used_connections')

max_connections_recomended = int(((memory * 1024 * 1024 * 1024) - global_buffers_sum) / thread_buffers_sum);
max_memory_usage           = round((global_buffers_sum + (max_connections_set * thread_buffers_sum)) / 1024 / 1024 / 1024);

table_data = [
  ['MySQL', 'Value', 'Description'],
  ['', memory, 'Avaible RAM Memory in Gb.'],
  ['', max_memory_usage, 'For actual config need this avaible memory in Gb.'],
  ['max_connections', max_connections_recomended, 'Recomended'],
  ['max_connections', max_connections_set, 'Set in MySQL'],
  ['max_used_connections', max_used_connections],
]
table = terminaltables.AsciiTable(table_data, 'Connections')
print(table.table)

