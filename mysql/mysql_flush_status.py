#!/usr/bin/python
# -*- coding: utf8 -*-

import subprocess
import sys

max_connections = []
hosts = [
  {'name': 'API: Master - API',       'ip': '10.10.2.105'},
  {'name': 'API: Slave  - Slor',      'ip': '10.10.1.43'},
  {'name': 'API: Slave  - Slor',      'ip': '10.10.3.35'},
  {'name': 'API: Slave  - Bouncer',   'ip': '10.10.3.115'},
  {'name': 'API: Slave  - Bouncer',   'ip': '10.10.4.191'},
  {'name': 'API: Slave  - Bouncer',   'ip': '10.10.5.242'},
  {'name': 'API: Slave  - Bouncer',   'ip': '10.10.0.212'},
  {'name': 'API: Slave  - Web',       'ip': '10.10.3.133'},
  {'name': 'API: Slave  - Web',       'ip': '10.10.1.200'},
  {'name': 'API: Slave  - Backup',    'ip': '10.10.0.119'},
  {'name': 'API: Slave  - API',       'ip': '10.10.2.200'},
  {'name': 'API: Slave  - API',       'ip': '10.10.1.49'},
  {'name': 'API: Slave  - API',       'ip': '10.10.2.219'},
  {'name': 'API: Slave  - API',       'ip': '10.10.2.223'},
  {'name': 'API: Slave  - API',       'ip': '10.10.1.225'},
  {'name': 'API: Slave  - API',       'ip': '10.10.4.83'},
  {'name': 'ChatV1: Master',          'ip': '10.10.6.73'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.3.22'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.7.89'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.1.188'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.3.89'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.5.90'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.7.39'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.3.143'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.0.83'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.0.67'},
  {'name': 'ChatV1: Slave',           'ip': '10.10.5.114'},
  {'name': 'ChatV2: Master',          'ip': '10.10.4.248'},
  {'name': 'ChatV2: Slave',           'ip': '10.10.4.51'},
  {'name': 'ChatV2: Slave',           'ip': '10.10.3.136'},
  {'name': 'ChatV2: Slave',           'ip': '10.10.3.137'},
  {'name': 'ChatV2: Slave',           'ip': '10.10.6.117'},
  {'name': 'Backoffice: Master',      'ip': '10.10.0.70'},
  {'name': 'Backoffice: Slave',       'ip': '10.10.5.57'},
  {'name': 'Backoffice: Slave',       'ip': '10.10.1.94'},
  {'name': 'Backoffice: Slave/Sphinx','ip': '10.10.7.7'},
  {'name': 'Backoffice: Slave',       'ip': '10.10.3.100'},
  {'name': 'Backoffice: Slave',       'ip': '10.10.3.32'},
  {'name': 'Backoffice: Slave',       'ip': '10.10.7.215'},
  {'name': 'Validation: Master',      'ip': '10.10.3.25'},
  {'name': 'Geo API: Master',         'ip': '10.10.0.158'},
  {'name': 'Rating: Master',          'ip': '10.10.2.13'},
  {'name': 'Rating: Slave',           'ip': '10.10.1.40'},
  {'name': 'Rating: Slave',           'ip': '10.10.1.39'},
  {'name': 'Notifications: Master',   'ip': '10.10.7.249'},
  {'name': 'Notifications: Slave',    'ip': '10.10.4.80'},
  {'name': 'Notifications: Slave',    'ip': '10.10.6.141'},
  {'name': 'Arya: Master',            'ip': '10.10.7.193'},
  {'name': 'Arya: Slave',             'ip': '10.10.1.167'},
  {'name': 'Arya: Slave',             'ip': '10.10.5.117'},
  {'name': 'Ganon: Master',           'ip': '10.10.1.53'},
  {'name': 'Ganon: Slave',            'ip': '10.10.1.138'}
]

mysql   = "mysql -h 127.0.0.1 -u root -p'' -Bse 'FLUSH STATUS'"

def execute(host, command):
  ssh = subprocess.Popen(["ssh", "%s" % host, command],
                            shell=False,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
  result = ssh.stdout.readlines()
  print result

  if result == []:
    return ''
  else:
    return result[0]

for host in hosts:
  print "Collecting data from host: %s" % host['ip']

  max_connections.append([host['ip'],
                          host['name'],
                          execute(host['ip'], command),
                          execute(host['ip'], mysql),
                          execute(host['ip'], facter)])

# Print a table:
row_header = ['Host', 'Name', 'my.cnf', 'Variable', 'Instance Class']
row_format = "{:>20}" * (len(row_header) + 1)

print ';'.join(row_header)
for row in max_connections:
  print ';'.join(row)
