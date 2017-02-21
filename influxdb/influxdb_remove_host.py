#!/usr/bin/env python

from influxdb import InfluxDBClient

client = InfluxDBClient('global-monitoring-node.heygo.com',
                        8086,
                        'telegraf',
                        'telegraf',
                        'telegraf')

result = client.query('SHOW MEASUREMENTS;')
result = list(result)

for item in result[0]:
  print "Remove data from table: %s" % item['name']
  result = client.query("DELETE FROM %s WHERE host =~ /ip/" % item['name'])
