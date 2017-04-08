#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

# brew install python3
# easy_install-3.6 PyMySQL


import pymysql

conn = pymysql.connect(host   = 'localhost',
                       port   = 3306,
                       user   = 'root',
                       passwd = '',
                       db     = 'spam')

cur = conn.cursor()

cur.execute("SELECT * FROM users")

print(cur.description)

print()

for row in cur:
    print(row)

cur.close()
conn.close()
