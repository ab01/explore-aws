from __future__ import print_function 
import json 
import boto3 
import botocore 
__author__ = 'CPM'

# Configurable options 
region = 'eu-west-1' 
topic = 'arn:aws:sns:eu-west-1:443377047944:poc-cpm-ire' 

# Global variables 
sns = boto3.client('sns', region_name=region) 

# Publishes to a specified SNS topic 
def sns_publish(topic_arn, subject, message): 
  try: 
    response = sns.publish( 
      TopicArn=topic_arn, 
      Subject=subject, 
      Message=message 
    ) 
    if not isinstance(response, dict): # log failed requests only 
      print('%s, %s' % (topic_arn, response)) 
    else: 
      print(response['ResponseMetadata']) 
  except botocore.exceptions.ClientError as e: 
    print('%s, %s, %s' % ( 
      topic_arn,
  ', '.join("%s=%r" % (k, v) for (k, v) in 
  e.response['ResponseMetadata'].iteritems()), 
  e.message))
  
# Entry point for lambda execution 
def lambda_handler(event, context): 
  try: 
    for record in event['Records']: 
      type = record['Sns']['Type'] 
      subject = record['Sns']['Subject'] 
      message = record['Sns']['Message'] 
      if type == 'Notification': 
        sns_publish(topic, subject, message) 
  except Exception as e: 
    print(e.message + ' Aborting...') 
    raise e 
	
# Default entry point outside lambda 
if __name__ == "__main__": 
  # Test load a sample json event during development testing 
  json_content = json.loads(open('sns_event.json', 'r').read()) 
  lambda_handler(json_content, None)
