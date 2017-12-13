#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

import re

var     = "(1062, \"Duplicate entry 'mysql_bin.000001-525' for key 'log_uidx'\")"
pattern = "(d\w+)$"

m = re.match(pattern, var)

print(m)
