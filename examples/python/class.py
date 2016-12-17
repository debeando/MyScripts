#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

class Foo:
  a = None

  def one(self):
    print 'Foo:one'
    self.two('Hi!')
    self.a = 'Hi!'

  def two(self, text):
    print 'Foo:one'
    print 'Foo:one -> %s' % text

  def run(self):
    print 'Foo:run'
    self.one()
    print self.a

f = Foo()
f.run()
