#!/usr/local/bin/python3.6

import os
import configparser

class Config():
  __instance = None;
  __config   = None;
  __file     = 'config.ini'

  def __init__(self, group, property, file = 'config.ini'):
    if Config.__instance == None:
      print("Instance " + name)
      Config.__instance = self;
      Config.__instance.read(name)

#    if Config.__instance != None:
#      raise Exception("This class implement singleton pattern.")
#    else:
#      Config.__instance = self

#  def getInstance():
#    if Config.__instance == None:
#      Config()
#    return Config.__instance

  def check_config_file(self):
    return os.path.isfile(self.__config_file)

  def set_config_file(self, path):
    self.__config_file = path

  def read(self, name):
    print("Read")
    #configs = configparser.ConfigParser()
    #configs.read(self.__config_file)
    #self.__config = dict(configs[name])

    #self.__config.setdefault('host',     '127.0.0.1')
    #self.__config.setdefault('port',     3306)
    #self.__config.setdefault('database', 'mysql')
    #self.__config.setdefault('user',     'root')
    #self.__config.setdefault('password', '')

  def value(self, property):
    if property in Config.__config:
      return Config.__config[property]

def main():
  print("Load main")

  Config('register').set_config_file('singleton.ini')
  Config('register').value('name')

  c = Config('crawler')
  r = Config('register')
  i = Config('ingest')

if __name__ == '__main__':
  main()
