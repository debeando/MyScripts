#!/usr/local/bin/python3.6
# -*- coding: utf-8 -*-

class Foo(object):
  _instance = None;
  _val      = None;

  def __init__(self):
    if Foo._instance == None:
      Foo._instance = self;

  def set(self, val):
    Foo._instance._val = val;

  def get(self):
    return Foo._instance._val;

a = Foo()
a.set('a')
b = Foo()
c = Foo()

print(a.get())
print(b.get())
print(c.get())
