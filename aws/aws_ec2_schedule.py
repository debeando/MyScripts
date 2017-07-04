#!/usr/local/bin/python3

import boto3.ec2
import datetime
import time

ec2      = boto3.client('ec2')
response = ec2.describe_instances()

def to_unixtimestamp(val):
  return int(datetime.datetime.strptime(val, '%H:%M').timestamp())

def state_change(current_time, start_at, stop_at):
  # Transform string time to unixtimestamp:
  current_time = to_unixtimestamp(current_time)
  start_at     = to_unixtimestamp(start_at)
  stop_at      = to_unixtimestamp(stop_at)

  if (start_at * -1) < (stop_at * -1):
    stop_at = stop_at + (24 * 60 * 60)

  # print(
  #   datetime.datetime.fromtimestamp(
  #       int(stop_at)
  #   ).strftime('%Y-%m-%d %H:%M:%S')
  # )

  # if now or today or nextday :

  if current_time == start_at == stop_at:
    return False

  if ((current_time * -1) < (start_at * -1) and (current_time * -1) >= (stop_at * -1)) :
    return False
  return True

# Test function: state_change
# ---------------------------
# print("- Current: 12:00, Start: 10:00, Stop: 11:00, Result: " + str(state_change('12:00', '10:00', '11:00'))) # True
# print("- Current: 12:00, Start: 10:00, Stop: 18:00, Result: " + str(state_change('12:00', '10:00', '18:00'))) # False
# print("- Current: 12:00, Start: 06:00, Stop: 10:00, Result: " + str(state_change('12:00', '06:00', '10:00'))) # True
# print("- Current: 12:00, Start: 10:00, Stop: 01:00, Result: " + str(state_change('12:00', '10:00', '01:00'))) # False
# print("- Current: 02:00, Start: 10:00, Stop: 01:00, Result: " + str(state_change('02:00', '10:00', '01:00'))) # True
# print("- Current: 12:00, Start: 12:00, Stop: 12:00, Result: " + str(state_change('12:00', '12:00', '12:00'))) # False
# print("- Current: 12:00, Start: 12:00, Stop: 12:01, Result: " + str(state_change('12:00', '12:00', '12:01'))) # True
# print("- Current: 12:00, Start: 11:00, Stop: 12:00, Result: " + str(state_change('12:00', '11:00', '12:00'))) # False
#
# exit(0)

for reservation in response['Reservations']:
  for instance in reservation['Instances']:
    keys = dict((i['Key'], i['Value']) for i in instance['Tags'])

    if instance['Tags'] is None:
      continue

    if 'StartAt' in keys and 'StopAt' in keys:
      current_time  = time.strftime('%H:%M')
      item          = {}
      item['id']    = instance['InstanceId']
      item['state'] = instance['State']['Name']

      for tag in instance['Tags']:
        if tag['Key'] == 'StartAt':
          item['start_at'] = tag['Value']
        elif tag['Key'] == 'StopAt':
          item['stop_at'] = tag['Value']

      if state_change(current_time, item['start_at'], item['stop_at']):
        if item['state'] == 'running':
          print("stopping...")
          # boto3.resource('ec2').instances.filter(InstanceIds=[item['id']]).stop()
      else:
        if item['state'] == 'stopped':
          print("starting...")
          # boto3.resource('ec2').instances.filter(InstanceIds=[item['id']]).start()

      print(item)
