#!/usr/local/bin/python3.6
# -*- coding: utf-8 -*-

import pymysql

class Connection(object):
  _connection = None
  _database   = None

  def __init__(self, database = 'mysql'):
    self._database = database
    self.connect()

  def connect(self):
    try:
      self._connection = pymysql.connect(
        host        = '127.0.0.1',
        port        = 33061,
        user        = 'admin',
        password    = 'admin',
        database    = self._database,
        charset     = 'utf8mb4',
        cursorclass = pymysql.cursors.DictCursor
      )
    except Exception as e:
      print("ERROR: MySQL Connection Couldn't be created... Fatal Error! " + str(e))
      sys.exit();

  def execute(self, sql):
    while True:
      try:
        cursor = self._connection.cursor()
        cursor.execute(sql)
        result = cursor.fetchall()
        cursor.close()
        return result
      except Exception as e:
        print("ERROR: MySQL Connection Couldn't be established, retry... Fatal Error! " + str(e))
        self.connect()
        continue
      break

a = Connection()
c = Connection('mysql')

print(a.execute('SELECT connection_id(), database()'))
print(a.execute('SELECT connection_id(), database()'))
print(c.execute('SELECT connection_id(), database()'))
print(c.execute('SELECT connection_id(), database()'))
print(a.execute('SELECT connection_id(), database()'))
print(c.execute('SELECT connection_id(), database()'))
print(a.execute('SELECT user()'))
print("Wait to kill a connection manualy and verify auto reconnect.")
print(c.execute('SELECT SLEEP(60)'))
print(c.execute('SELECT user, host FROM mysql.user'))

users = c.execute('SELECT user, host FROM mysql.user')
for user in users:
  print(user)
