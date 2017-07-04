#!/usr/local/bin/python3

#
# Probar el código en local:
# ------------------------------------------------------------------------------
# $ python3
# >>> import aws_lambda_ec2_schedule as s
# >>> s.to_unixtimestamp('10:00')
# -2208952800
# >>> s.verify_schedule('12:00', '10:00', '11:00')
# True
#
# Ejecutar los test de la siguiente forma:
# ------------------------------------------------------------------------------
# $ ./aws_lambda_ec2_schedule_unittest.py
#
#
# monday tuesday wednesday thursday friday saturday sunday
# MTWTFSS
# 0123456
# 01234II U: Ignore Schedule, startUp all day (24h)
# 01234DD D: Ignore Schedule, shutDown all day (24h)
# SSSSSDD S: Schedule
#
#
# 24h - 5h down 19h up
# (24 * 7) * 4 = 672
# (19 * 5) * 4 = 380
# ------------------
#                292 43%
#
# (24 * 7) * 4 = 672
# (19 * 7) * 4 = 532
# ------------------
#                140 20%

import boto3.ec2
import datetime
import time
import re

def to_unixtimestamp(val):
    return int(datetime.datetime.strptime(val, '%H:%M').timestamp())

def out_of_time(current_time, start_at, stop_at):
    current_time = to_unixtimestamp(current_time)
    start_at     = to_unixtimestamp(start_at)
    stop_at      = to_unixtimestamp(stop_at)

    if (start_at * -1) < (stop_at * -1):
        stop_at = stop_at + (24 * 60 * 60)

    if current_time == start_at == stop_at:
        return False

    if ((current_time * -1) < (start_at * -1) and (current_time * -1) >= (stop_at * -1)) :
        return False
    return True

def get_instances():
    items = []
    ec2   = boto3.client('ec2')
    desc  = ec2.describe_instances()

    for reservation in desc['Reservations']:
        for instance in reservation['Instances']:
            if instance['Tags'] is None:
                continue

            keys = dict((i['Key'], i['Value']) for i in instance['Tags'])

            if 'StartAt' in keys and 'StopAt' in keys:
                item          = {}
                item['id']    = instance['InstanceId']
                item['state'] = instance['State']['Name']
                item['info']  = 'Ok'

                for tag in instance['Tags']:
                    if tag['Key'] == 'StartAt':
                        item['start_at'] = tag['Value']
                    elif tag['Key'] == 'StopAt':
                        item['stop_at'] = tag['Value']
                    elif tag['Key'] == 'WorkDays':
                        item['workdays'] = tag['Value']

                items.append(item)

    return items

def is_valid_workdays(workdays):
    workdays = workdays.upper()
    weekday  = datetime.datetime.today().weekday()

    if len(workdays) == 7 and re.match("^[UDS]*$", workdays):
        return workdays[weekday]
    return False

def stop(instance):
    if instance['state'] == 'running':
        instance['info'] = 'stopping'
        boto3.resource('ec2').instances.filter(InstanceIds=[instance['id']]).stop()

def start(instance):
    if instance['state'] == 'stopped':
        instance['info'] = 'starting'
        boto3.resource('ec2').instances.filter(InstanceIds=[instance['id']]).start()

def lambda_handler(event, context):
    current_time = time.strftime('%H:%M')

    for instance in get_instances():
        weekday = is_valid_workdays(instance['workdays'])

        if weekday == 'D':
            stop(instance)
        elif weekday == 'U':
            start(instance)
        else:
            if out_of_time(current_time, instance['start_at'], instance['stop_at']) :
                stop(instance)
            else:
                start(instance)

        print("EC2 Schedule Verify at %s %s Instance-id: %s (%s => %s) Schedule: [Start At: %s, Stop At: %s, WorkDays: %s]" % (current_time, datetime.datetime.today().weekday(), instance['id'], instance['state'], instance['info'], instance['start_at'], instance['stop_at'], instance['workdays']))
