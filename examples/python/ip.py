#!/usr/bin/env python

import re
import sys

def is_valid_ip(ip):
  m = re.match(r"^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$", ip)
  return bool(m) and all(map(lambda n: 0 <= int(n) <= 255, m.groups()))

print is_valid_ip(sys.argv[1])
