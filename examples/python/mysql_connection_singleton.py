#!/usr/local/bin/python3.6
# -*- coding: utf-8 -*-

import pymysql
import sys
import time

class Connection(object):
  _connection  = None;
  _instance    = None;

  def __init__(self, name = None):
    if Connection._instance == None:
      Connection._instance = self;

  def instance(self):
    return Connection._instance;

  def connect(self):
    try:
      Connection._connection = pymysql.connect(
        host        = '127.0.0.1',
        port        = 3306,
        user        = 'root',
        password    = '',
        charset     = 'utf8mb4',
        autocommit  = True,
        use_unicode = True,
        cursorclass = pymysql.cursors.DictCursor
      )
    except Exception as e:
      print("ERROR: MySQL Connection Couldn't be created... Fatal Error! " + str(e))
      sys.exit();

  def database(self, name = None):
    Connection._connection.select_db(name)

  def close(self):
    try:
      Connection._connection.close();
    except:
      pass;

  def query(self, sql):
    try:
      Connection._connection.ping()
      cursor = Connection._connection.cursor()
      cursor.execute(sql)
      result = cursor.fetchall()
      cursor.close()
      return result
    except Exception as e:
      print("ERROR: " + str(e))
      pass

a = Connection()
a.connect()
print(a.query('SELECT connection_id(), database()'))
a.database('mysql')
print(a.query('SELECT connection_id(), database()'))

c = Connection()
c.connect()
print(c.query('SELECT connection_id(), database()'))
c.database('mysql')
time.sleep(10)
print(c.query('SELECT connection_id(), database()'))

b = Connection()
b.instance()
print(b.query('SELECT connection_id(), database()'))
b.database('mysql')
print(b.query('SELECT connection_id(), database()'))
b.close()
time.sleep(10)
