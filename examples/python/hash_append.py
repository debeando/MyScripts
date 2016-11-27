#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import json

a = []
b = [{'key': 'A'}, {'key': 'B'}]

def foo():
  c = []
  for item in b:
    c.append({ 'text': item['key'] })
  return c

print foo()
