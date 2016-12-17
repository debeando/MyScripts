#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

results = ['', '1', '2', '3']
results = filter(None, results)
results = map(int, results)

print results
