#!/usr/local/bin/python3.6
# -*- coding: utf-8 -*-
# -*- mode: python -*-

import math
import time

class Chunk():
  _size     = 1
  _sleep    = 0
  _max      = 1
  _min      = 1
  _parts    = 0
  _time     = time.time()
  _duration = 0
  _chunk    = 0
  _eta      = 0

  def __init__(self, size = 1, sleep = 0, min = 1, max = 1):
    self._size  = size
    self._sleep = sleep
    self._max   = max
    self._min   = min
    self._parts = self._parts()

  def _parts(self):
    return int(self._max / self._size)

  def _percentage(self):
    return "%.2f" % round((100 * self._chunk) / self._parts, 2)

  def _start(self):
    return (self._end() - self._size) + 1

  def _end(self):
    return self._chunk * self._size

  def _wait(self):
    time.sleep(self._sleep)

  def _set_time(self):
    self._time = int(time.time())

  def eta(self):
    self._duration = (((int(time.time()) - self._time) + self._duration) / 2)
    self._eta = round(((self._parts - self._chunk) - 1) * self._duration, 2)
    self._eta = abs(self._eta)
    self._set_time()
    return self._eta;

  def iterate(self):
    for self._chunk in range(self._min, self._parts):
      yield {
        "chunk":      self._chunk,
        "start":      self._start(),
        "end":        self._end(),
        "percentage": self._percentage(),
        "eta":        self.eta()
      }
      self._wait()

def main():
  c = Chunk(size = 2, max = 20, sleep=1)

  for a in c.iterate():
    print(a)

if __name__ == '__main__':
  main()
