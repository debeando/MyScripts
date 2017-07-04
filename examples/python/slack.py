#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import urllib2
import json

SLACK_WEB_HOOK = "https://hooks.slack.com"
SLACK_TOKEN    = "T02TQ40HJ/B519LJ2QP/XyEKcIB6LWwWGLNhDiDQToss"
SLACK_USER     = "AWS Lambda"
SLACK_CHANNEL  = "#alerts"

headers = {'content-type': 'application/json'}
data    = {
            'channel': SLACK_CHANNEL,
            'username': SLACK_USER,
            'text': '*Suspicious IP Address* ',
            'attachments': [
              {
                'color': 'danger',
                'footer': 'Too many bad request',
                'fields': [
                  {
                    'title': 'IP Address',
                    'value': 'abc',
                  }
                ]
              }
            ]
          }

req = urllib2.Request(url=SLACK_WEB_HOOK + '/services/' + SLACK_TOKEN,
                      data=json.dumps(data))
f = urllib2.urlopen(req)
print f.read()
