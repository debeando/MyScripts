#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import logging
import time

from logging.handlers import RotatingFileHandler

def create_rotating_log(path):
  """
  Creates a rotating log
  """
  logging.basicConfig(
    filename='test.log',
    format='%(asctime)s - %(levelname)s - %(message)s',
    level=logging.DEBUG
  )

  # add a rotating handler
  handler = RotatingFileHandler(maxBytes=(1024 * 1024 * 10),
                                backupCount=3)
  logger.addHandler(handler)

  for i in range(10):
    logger.info("This is test log line %s" % i)
    time.sleep(1.5)

#----------------------------------------------------------------------
if __name__ == "__main__":
  log_file = "test.log"
  create_rotating_log(log_file)
