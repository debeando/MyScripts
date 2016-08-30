#!/usr/bin/python
# -*- coding: utf-8 -*-

import mysql.connector

conn = mysql.connector.connect(host='10.11.5.125',
                               database='dbchat_test',
                               user='dbchat_test',
                               password='test',
                               charset='utf8mb4')
cursor = conn.cursor()


query = "DELETE FROM messages"
cursor.execute(query)
conn.commit()

query = "INSERT INTO messages (message_id,message_text,message_type,talker_id,conversation_id,sent_at,status) VALUES ('11111111-1111-1111-1111-111111111111','Nice emoji 😀!',0,0,'11111111-1111-1111-1111-111111111111','2016-08-08 10:10:00.000',1)"
cursor.execute(query)
conn.commit()

query = ("SELECT message_text FROM messages WHERE id = {0}").format(cursor.lastrowid)
cursor.execute(query)

for row in cursor:
  print row[0]

cursor.close()
conn.close()
