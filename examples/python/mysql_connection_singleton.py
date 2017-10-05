#!/usr/local/bin/python3.6
# -*- coding: utf-8 -*-

import pymysql

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
        port        = 33061,
        user        = 'admin',
        password    = 'admin',
        charset     = 'utf8mb4',
        cursorclass = pymysql.cursors.DictCursor
      )
    except Exception as e:
      print("ERROR: MySQL Connection Couldn't be created... Fatal Error! " + str(e))
      sys.exit();

  def database(self, name = None):
    Connection._connection.select_db(name)

  def close(self):
    try:
      while not Connection._connection.is_empty():
        Connection._connection.close();
    except:
      pass;

  def fetchone(self, sql):
    cursor = Connection._connection.cursor()
    cursor.execute(sql)
    result = cursor.fetchone()
    cursor.close()
    return result

a = Connection()
a.connect()
print(a.fetchone('SELECT connection_id(), database()'))
a.database('mysql')
print(a.fetchone('SELECT connection_id(), database()'))

c = Connection()
c.connect()
print(c.fetchone('SELECT connection_id(), database()'))
c.database('mysql')
print(c.fetchone('SELECT connection_id(), database()'))

b = Connection()
b.instance()
print(b.fetchone('SELECT connection_id(), database()'))
b.database('mysql')
print(b.fetchone('SELECT connection_id(), database()'))
