#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# ==============================================================================
# Motivation:
# ------------------------------------------------------------------------------
# Many tools replay only "slow log" because have a database name in the table
# where is stored, and used this tool for create Benchmark when change index or
# schema in another slave to verify changes on bad queries registered in slow
# log. For this particulate case, require more "logic" to determine this query
# comes from this database and replay in another database server. For this case
# I build this script.
#
# - tcpdump: The problem to use this is to impossible identify database name when
#            is running query.
# - pt-log-player: (Deprecated) Only replay slow log.
# - Percona Playback: (Beta) Only replay slow log.
#
# ==============================================================================
# MySQL Configurations for general_log:
# ------------------------------------------------------------------------------
# SET GLOBAL general_log = OFF;
# TRUNCATE mysql.general_log;
# ALTER TABLE mysql.general_log ENGINE = MyISAM;
# ALTER TABLE mysql.general_log ADD INDEX general_log_idx (command_type, thread_id, event_time);
# SHOW VARIABLES LIKE 'log_output';
# SHOW VARIABLES LIKE 'general_log';
# SET GLOBAL log_output = 'TABLE';
# SET GLOBAL general_log = ON;
# SET GLOBAL sql_buffer_result = ON;
#

import json
import logging
import re
import sys
import threading
import time
import warnings

try:
  import configparser
except ImportError:
  sys.exit("You need configparser, please run 'pip install configparser'.")

try:
  import pymysql
except ImportError:
  sys.exit("You need pymysql, please run 'pip install pymysql'.")

class Log:
  def __init__(self):
    self._logging = logging.basicConfig(
      filename="mysql_replay.log",
      level=logging.DEBUG,
      format='%(asctime)s %(levelname)s %(message)s'
    )

  def info(self, host, database, message):
    logging.info("[%s(%s)]: %s" % (host, database, message))

  def debug(self, host, database, message):
    logging.debug("[%s(%s)]: %s" % (host, database, message))

  def error(self, host, database, message):
    logging.error("[%s(%s)]: %s" % (host, database, message))

class Config:
  _config      = None
  _config_file = 'mysql_replay.ini'

  def __init__(self, name):
    self._config = configparser.ConfigParser()
    self._config.readfp(open(self._config_file))
    self._config = self._config[name]

class Database(Config):
  def __init__(self):
    Config.__init__(self, 'filters')

  def list(self):
    return self._config.items()

class Connection(Config):
  _connection = None

  def __init__(self, name, database):
    Config.__init__(self, name)

    self._config['database'] = database

    try:
      self._connection = pymysql.connect(
        host        = self._config['host'],
        port        = int(self._config['port']),
        user        = self._config['user'],
        password    = self._config['password'],
        database    = self._config['database'],
        charset     = 'utf8mb4',
        cursorclass = pymysql.cursors.DictCursor
      )
      Log().info(self._config['host'], self._config['database'], 'Connected!')

    except Exception as e:
      print("ERROR: MySQL Connection Couldn't be created... Fatal Error! " + str(e))
      sys.exit();

  def execute(self, sql):
    try:
      Log().debug(self._config['host'], self._config['database'], sql)
      cursor = self._connection.cursor()
      cursor.execute(sql)
      cursor.close()
    except Exception as e:
      Log().error(self._config['host'], self._config['database'], json.dumps(
        [{
          'code':    e[0],
          'message': e[1],
          'sql':     sql}
        ])
      )

  def fetchone(self, sql):
    Log().info(self._config['host'], self._config['database'], sql)
    cursor = self._connection.cursor()
    cursor.execute(sql)
    result = cursor.fetchone()
    cursor.close()
    return result

  def fetchall(self, sql):
    Log().info(self._config['host'], self._config['database'], sql)
    cursor = self._connection.cursor()
    cursor.execute(sql)
    result = cursor.fetchall()
    cursor.close()
    return result

class From(Connection):
  def __init__(self, database):
    Connection.__init__(self, 'from', database)

  def read(self, filter):
    counter = 0
    result  = self.fetchone('SELECT connection_id() AS connection_id')

    while True:
      # Increase counter to trash mysql.general_log
      counter += 1

      # Caputure queries
      sql = ("SELECT argument "
             "FROM mysql.general_log "
             "WHERE command_type = 'Query' "
             "AND user_host LIKE '%%%s%%' "
             "AND UPPER(argument) LIKE 'SELECT%%' "
             "AND thread_id <> %d "
             "AND event_time = NOW() - INTERVAL 1 SECOND"
             % (
              filter,
              result['connection_id']
            ))

      results = self.fetchall(sql)

      for row in results:
        yield row['argument']

      # Trash general log:
      if counter == 60:
        self.execute("SET GLOBAL general_log = OFF; "
                     "TRUNCATE mysql.general_log; "
                     "SET GLOBAL general_log = ON;")

      # Wait 1s
      time.sleep(1)

class To(Connection):
  def __init__(self, database):
    Connection.__init__(self, 'to', database)

def replay(database, filter):
  f = From(database)
  t = To(database)

  for sql in f.read(filter):
    t.execute(sql)

def main():
  # Ignore all warnings messages
  warnings.simplefilter("ignore")

  # Start each replay by database:
  threads = []
  for database, filter in Database().list():
    t = threading.Thread(target=replay, args=(database, filter))
    threads.append(t)

  # Start all threads
  for thread in threads:
    thread.start()

  # Wait for all of them to finish
  for thread in threads:
    thread.join()

if __name__ == "__main__":
  main()
