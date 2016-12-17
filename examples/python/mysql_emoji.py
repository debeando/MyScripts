#!/usr/bin/python
# -*- coding: utf-8 -*-

import mysql.connector

conn = mysql.connector.connect(host='127.0.0.1',
                               database='test',
                               user='admin',
                               password='vagrant',
                               charset='utf8mb4')
cursor = conn.cursor()


query = "DELETE FROM messages"
cursor.execute(query)
conn.commit()

query = "INSERT INTO messages (message) VALUES ('Nice emoji 😀!')"
cursor.execute(query)
conn.commit()

query = ("SELECT message FROM messages WHERE id = {0}").format(cursor.lastrowid)
cursor.execute(query)

for row in cursor:
  print row[0]

cursor.close()
conn.close()
