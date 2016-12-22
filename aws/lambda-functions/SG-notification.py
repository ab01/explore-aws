from __future__ import print_function
import json
import boto3
import ast

ec2 = boto3.client('ec2')
client = boto3.client('sns')

print('Loading function')

def lambda_handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))
    print ("event message:-" , event)
    #print ("event message:-" , context)
    payload = json.loads(event['Records'][0]['Sns']['Message'])
    #payload = (event['Records'][0]['Sns']['Message'])
    print ("-----",payload)
    try:
        message = payload['configurationItemDiff']['changeType']
        sgid = payload['configurationItem']['resourceId']
        subject = (event['Records'][0]['Sns']['Subject'])
        FinalMessage = subject+'\n'+"Change Type:- "+message+'\n'+str(payload)
        #print ("Subjetc :-", FinalMessage)

        print("Sg Details: " + sgid)
        print ("From SNS",message)
        service_name = ''
        owner_Name = ''
        name = ''
        stage = ''
        print ("Tags:", payload['configurationItem']['tags'])
        payload = payload['configurationItem']
        if payload.has_key('tags'):
            if payload['tags'].has_key('Stage'):
                stage = payload['tags']['Stage']
            if payload['tags'].has_key('Name'):
                name = payload['tags']['Name']
            if payload['tags'].has_key('Service'):
                service_name = payload['tags']['Service']
            if payload['tags'].has_key('Owner'):
                owner_Name = payload['tags']['Owner']

        if stage == 'dev' or stage == 'Dev' or name.find('DEV') >-1 or name.find('Dev')>-1 or name.find('dev') >-1:
            output = [name, service_name, owner_Name, stage]
            print ("Output: ", output)
            response = client.publish(TargetArn='arn:aws:sns:us-east-1:137541667968:sg-alert',Message=str(FinalMessage),Subject='Testing')

        return message
    except Exception as e:
        print ("THERE IS SOME ERROR",e)
