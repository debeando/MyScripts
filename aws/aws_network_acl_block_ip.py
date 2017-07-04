#!/usr/local/bin/python3

import boto3

networkAclId  = 'acl-26cc1243'
ignoreEntries = [100, 32767]

session = boto3.Session()
client  = session.client('ec2')
acls    = client.describe_network_acls()


def getMaxOfRuleNumbers():
    result = [0]
    for acl in acls['NetworkAcls']:
        if acl['NetworkAclId'] == networkAclId:
            for entries in acl['Entries']:
                if entries['RuleNumber'] not in ignoreEntries:
                    if entries['RuleAction'] == 'deny':
                        result.append(entries['RuleNumber'])
    return max(result)

def existEntry(cidrBlock):
    for acl in acls['NetworkAcls']:
        if acl['NetworkAclId'] == networkAclId:
            for entries in acl['Entries']:
                if entries['RuleNumber'] not in ignoreEntries:
                    if entries['RuleAction'] == 'deny':
                        if cidrBlock == entries['CidrBlock']:
                            return True
    return False


def createNetworkAclIngressEntry(ruleNumber, cidrBlock):
    params = {}
    params["NetworkAclId"] = networkAclId
    params["RuleNumber"]   = ruleNumber
    params["Protocol"]     = '-1'
    params["CidrBlock"]    = cidrBlock
    params["Egress"]       = False
    params["RuleAction"]   = "DENY"

    client.create_network_acl_entry(**params)


def blockIp(ip):
    ip = ip + '/32'

    if not existEntry(ip):
        maxId = getMaxOfRuleNumbers()
        maxId = maxId + 1

        if maxId not in ignoreEntries:
            createNetworkAclIngressEntry(maxId, ip)
            print("BlockIP: %s" % ip)

blockIp('174.129.214.250')
