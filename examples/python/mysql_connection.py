#!/usr/local/bin/python3.6
# -*- coding: utf-8 -*-

import pymysql

class Connection(object):
  _connection = None;

  def __init__(self):
    try:
      self._connection = pymysql.connect(
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
    self._connection.select_db(name)

  def close(self):
    try:
      while not self._connection.is_empty():
        self._connection.close();
    except:
      pass;

  def fetchone(self, sql):
    cursor = self._connection.cursor()
    cursor.execute(sql)
    result = cursor.fetchone()
    cursor.close()
    return result

  def fetchall(self, sql):
    cursor = self._connection.cursor()
    cursor.execute(sql)
    result = cursor.fetchall()
    cursor.close()
    return dict(result)

a = Connection()
print(a.fetchone('SELECT connection_id(), database()'))
a.database('mysql')
print(a.fetchone('SELECT connection_id(), database()'))

c = Connection()
print(c.fetchone('SELECT connection_id(), database()'))
c.database('mysql')
print(c.fetchone('SELECT connection_id(), database()'))

c.fetchall('SHOW VARIABLES')
