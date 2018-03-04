#!/usr/local/bin/python3.6
# -*- coding: utf8 -*-

import configparser
import optparse
import os
import pymysql
import re

config_values  = None
mysql_values   = None
default_values = None

ignore_variable = [
  'innodb-buffer-pool-instances',
  'innodb-file-format-max',
  'innodb-io-capacity-max',
  'innodb-open-files',
  'innodb-page-cleaners',
  'innodb-use-native-aio',
  'large-page-size',
  'log-error',
  'log-error-verbosity',
  'log-warnings',
  'optimizer-trace',
  'pid-file',
  'report-port',
  'sql-slave-skip-counter',
]

def num(s):
  try:
    return int(s)
  except ValueError:
    return float(s)

def is_num(s):
  try:
    complex(s)
  except ValueError:
    return False

  return True

def load_config_values(path):
  if os.path.isfile(path):
    config = configparser.ConfigParser()
    config.read(path)
    return config
  else:
    print("File not exist: %s" % path)
    exit(1)

def load_mysql_values(host, port, user, password):
  try:
    connection = pymysql.connect(
      host        = host,
      port        = port,
      user        = user,
      password    = password,
      cursorclass = pymysql.cursors.DictCursor
    )
  except Exception as e:
    print("ERROR %s: %s" % (e.args[0], e.args[1]))
    exit(1)

  sql    = "SHOW GLOBAL VARIABLES;"
  cursor = connection.cursor()
  cursor.execute(sql)
  result = cursor.fetchall()
  cursor.close()

  return result

def load_default_values():
  command = "mysqld --verbose --help"
  value = os.popen(command).read()
  value = str(value)
  value = value.strip()
  return value

def parse_default_values():
  # Get all stdout from command:
  default   = load_default_values()

  # Extract only variables and values:
  match     = re.search(r'\-{3,}\s\-{3,}\n(?P<variables>[\s\S]+)\n\n', default, re.MULTILINE)
  variables = match['variables']

  # Parse variables and values:
  regex   = re.compile(r'(?P<variable>[\w\-]+)\s+(?P<value>.*)', re.MULTILINE)
  matches = [m.groups() for m in regex.finditer(variables)]

  return matches

def get_config_variable(variable_name):
  if variable_name in config_values['mysqld']:
    return config_values['mysqld'][variable_name]

def get_default_value(variable_name):
  value = None

  for default in default_values:
    if default[0] == variable_name:
      value = default[1]
      break

  if not value:
    return None
  elif value == "FALSE":
    return "OFF"
  elif value == "TRUE":
    return "ON"
  elif is_num(value):
    value = num(value)

  return value

def compare_variables():
  invalid = 0
  for variable in mysql_values:
    variable_name = variable["Variable_name"].replace("_", "-")

    if not variable["Value"]:
      variable["Value"] = None
    elif is_num(variable["Value"]):
      variable["Value"] = num(variable["Value"])

    var = {
      "name": variable_name,
      "current": variable["Value"],
      "default": get_default_value(variable_name),
      "config": get_config_variable(variable_name),
      "valid": False
    }

    if var["config"] == None and var["current"] == var["default"]:
      var["valid"] = True
    elif var["config"] == var["current"] and var["default"] != var["current"]:
      var["valid"] = True
    elif var["config"] == var["current"] == var["default"]:
      var["valid"] = True
    elif var["config"] == None and var["default"] == None and var["current"]:
      var["valid"] = True
    elif var["default"] != var["current"] and var["default"] == -1:
      var["valid"] = True
    elif var["default"] == "(No default value)":
      var["valid"] = True
    elif var["name"] in ignore_variable:
      var["valid"] = True

    # Print only suspicious variables:
    if var["valid"] == False:
      invalid += 1
#      print(var)

  exit(invalid)

if __name__ == '__main__':
  parser = optparse.OptionParser("usage: %prog [options]", version="0.1.0")
  parser.add_option("-H", "--host",
                    default = "127.0.0.1",
                    dest    = "host",
                    help    = "Connect to host.")
  parser.add_option("-u", "--user",
                    default = "root",
                    dest    = "user",
                    help    = "User for login if not current user.")
  parser.add_option("-p", "--password",
                    default = "",
                    dest    = "password",
                    help    = "Password to use when connecting to server.")
  parser.add_option("-P", "--port",
                    default = 3306,
                    dest    = "port",
                    type    = int,
                    help    = "Port number to use for connection.")
  parser.add_option("-c", "--config",
                    default = "/etc/mysql/my.cnf",
                    dest    = "config",
                    help    = "Read options from configuration file.")

  (opts, args) = parser.parse_args()

  config_values  = load_config_values(opts.config)
  mysql_values   = load_mysql_values(opts.host, opts.port, opts.user, opts.password)
  default_values = parse_default_values()

  compare_variables()


#--collector.textfile.directory
#
#mysql_check_default_config 2
