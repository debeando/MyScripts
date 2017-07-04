import boto3.ec2
import datetime
import time

def to_unixtimestamp(val):
    return int(datetime.datetime.strptime(val, '%H:%M').timestamp())

def verify_schedule(current_time, start_at, stop_at):
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

                items.append(item)

    return items

def lambda_handler(event, context):
    instances    = get_instances()
    current_time = time.strftime('%H:%M')

    for instance in instances:
        if verify_schedule(current_time, instance['start_at'], instance['stop_at']) :
            if instance['state'] == 'running':
                instance['info'] = 'stopping'
                boto3.resource('ec2').instances.filter(InstanceIds=[instance['id']]).stop()

        else:
            if instance['state'] == 'stopped':
                instance['info'] = 'starting'
                boto3.resource('ec2').instances.filter(InstanceIds=[instance['id']]).start()

        print("EC2 Schedule Verify at %s Instance-id: %s (%s => %s) Schedule: [Start At: %s, Stop At: %s]" % (current_time, instance['id'], instance['state'], instance['info'], instance['start_at'], instance['stop_at']))

    return instances
