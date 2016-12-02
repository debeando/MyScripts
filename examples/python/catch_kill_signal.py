#!/usr/bin/env python

import signal
import sys
import time
 
def signal_term_handler(signal, frame):
  print 'Catch kill signal'
  sys.exit(0)
 
signal.signal(signal.SIGTERM, signal_term_handler)

try:
  while True:
	  print '.'
	  time.sleep(1)

except KeyboardInterrupt:
  print 'Catch Ctrl-C'
