#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

import http.client
import urllib.parse
import json

SLACK_WEB_HOOK = "hooks.slack.com"
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

uri  = SLACK_WEB_HOOK
conn = http.client.HTTPSConnection(uri)
data = json.dumps(data)
conn.request("POST", "/services/" + SLACK_TOKEN, data, headers)

conn.getresponse()
#print(response.status)
