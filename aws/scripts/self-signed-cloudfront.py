#!/usr/bin/python
import time,boto,rsa
from boto import cloudfront
from boto.cloudfront import distribution

#AWS_ACCESS_KEY_ID="your access key"
#AWS_SECRET_ACCESS_KEY="your secret access key"


conn = boto.cloudfront.CloudFrontConnection()
dist = conn.get_all_distributions()
a=dist[0].get_distribution()
#Set parameters for URL
key_pair_id = "XXXXXXXXXXXXX" #cloudfront security key
priv_key_file = "XXXXXXXXXX.pem" #cloudfront private keypair file
expires = int(time.time()) + 60 #1 min
url="https://XXXXXXX.cloudfront.net/XXXXXX"
signed_url = a.create_signed_url(url, key_pair_id, expires, private_key_file=priv_key_file)
print signed_url

# signed url via aws command line
#aws cloudfront sign --url https://XXXXXXXXXXXXX.cloudfront.net/hello.txt --key-pair-id XXXXXXXXXXXXX #cloudfront Access key --private-key file://XXXXXXXXXX.pem --date-less-than 2022-12-05
