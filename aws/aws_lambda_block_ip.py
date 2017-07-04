import boto3
import http.client
import json
import operator
import os
import urllib
import urllib.parse

session = boto3.Session()
ec2     = session.client('ec2')
s3      = session.client('s3')

# General rules:
MAX_REQUESTS  = int(os.environ['MAX_REQUESTS'])
networkAclId  = 'acl-26cc1243'
ignoreEntries = [100, 32767]
LINE_FORMAT   = {
    'source_ip': 2,
    'code'     : 7
}

# Get Slack settings:
SLACK_WEB_HOOK = os.environ['SLACK_WEB_HOOK']
SLACK_TOKEN    = os.environ['SLACK_TOKEN']
SLACK_USER     = os.environ['SLACK_USER']
SLACK_CHANNEL  = os.environ['SLACK_CHANNEL']

def getMaxOfRuleNumbers():
  result = [0]
  acls   = ec2.describe_network_acls()

  for acl in acls['NetworkAcls']:
    if acl['NetworkAclId'] == networkAclId:
      for entries in acl['Entries']:
        if entries['RuleNumber'] not in ignoreEntries:
          if entries['RuleAction'] == 'deny':
            result.append(entries['RuleNumber'])
  return max(result)

def existEntry(ip):
  acls = ec2.describe_network_acls()
  for acl in acls['NetworkAcls']:
    if acl['NetworkAclId'] == networkAclId:
      for entries in acl['Entries']:
        if entries['RuleNumber'] not in ignoreEntries:
          if entries['RuleAction'] == 'deny':
            if ip + '/32' == entries['CidrBlock']:
              return True
  return False

def createNetworkAclIngressEntry(ruleNumber, ip):
  params = {}
  params["NetworkAclId"] = networkAclId
  params["RuleNumber"]   = ruleNumber
  params["Protocol"]     = '-1'
  params["CidrBlock"]    = ip + '/32'
  params["Egress"]       = False
  params["RuleAction"]   = "DENY"

  client.create_network_acl_entry(**params)
  print("Create new entry on NetworkACL to block IP: %s" % ip)

def slackNotify(ip):
  # Send notification to Slack Webhook:
  data = {'channel': SLACK_CHANNEL,
          'username': SLACK_USER,
          'text': '*AutoBlocked IP Address in NetworkACL* ',
          'attachments': [{
              'color': 'danger',
              'footer': 'Too many bad requests',
              'fields': [{
                          'value': ip,
              }]
          }]
      }

  uri     = SLACK_WEB_HOOK
  conn    = http.client.HTTPSConnection(uri)
  data    = json.dumps(data)
  headers = {'Content-Type': 'application/json'}

  conn.request("POST", "/services/" + SLACK_TOKEN, data, headers)
  conn.getresponse()

def lambda_handler(event, context):
  for record in event['Records']:
    result = {}
    bucket = record['s3']['bucket']['name']
    key    = record['s3']['object']['key']

    response = s3.get_object(Bucket=bucket, Key=key)
    body     = response['Body'].read()
    rows     = body.splitlines()

    for line in rows:
      try:
        line       = line.decode("utf-8")
        line_data  = line.split(' ')
        ip_address = line_data[LINE_FORMAT['source_ip']].split(':')[0]
        code       = int(line_data[LINE_FORMAT['code']])

        if code not in [200, 301, 302]:
          if ip_address in result.keys():
            result[ip_address] += 1
          else:
            result[ip_address] = 1
      except Exception:
        print ("Error to process line: %s" % line)

    # Sort IP Address by amount of bad requests:
    result = sorted(result.items(), key=operator.itemgetter(1), reverse=True)

    # Remove not important bad requests:
    result = [item for item in result if item[1] >= MAX_REQUESTS]

    # Block IP in Network ACL:
    for ip in result:
      ip = ip[0]

      if not existEntry(ip):
        maxId = getMaxOfRuleNumbers()
        maxId = maxId + 1

        if maxId not in ignoreEntries:
          createNetworkAclIngressEntry(maxId, ip)
          slackNotify(ip)

