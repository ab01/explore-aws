#!/bin/bash

# Description: Script for setting up monitoirng for application
# Created on : Fri Aug 19 14:00:58 JST 2016
# Created by : prasanth_gv@amway.com
# Monitors follwoing parameters
# 1. Process monitoring

## Version Control
# 1.0 : Fri Aug 19 14:00:58 JST 2016 : Initial Version

## Exit Codes
# 0   : Successful exit
# 1   : Failed to set cloudwatch alarm


# Reload SSH to pick up any application-specific customizations
yum -y install unzip

if [ x$INSTANCE_ID != x ] && [ x$INSTANCE_NAME != x ] && [ $SNS != UNKNOWN ]; then

### Duplicate the below block for each process you wants to monitor

	###BLOCK STARTS
	# Process check for Syslog
	PROCESSNAME="solr"
	PROCESSSTRING="'solr'"

	# Set up custom metrics & critical alarms for process
	echo "*/5 * * * * root /usr/bin/aws cloudwatch put-metric-data --region $AWSRegion --metric-name ${PROCESSNAME} --namespace "System/Linux" --value \`ps -ef | egrep ${PROCESSSTRING} | grep -v grep | wc -l\` --dimensions InstanceId=${INSTANCE_ID}" > /etc/cron.d/awscloudwatch-${PROCESSNAME}

	chmod 644 /etc/cron.d/awscloudwatch-${PROCESSNAME}
	service crond reload

	aws cloudwatch put-metric-alarm --region=$AWSRegion --alarm-name ${INSTANCE_NAME}-${INSTANCE_ID}-${PROCESSNAME}Critical --alarm-description "Critical - ${PROCESSNAME} not running" --metric-name ${PROCESSNAME} --namespace System/Linux --statistic Average --period 300 --threshold 2 --comparison-operator LessThanThreshold --dimensions Name=InstanceId,Value=${INSTANCE_ID} --evaluation-periods 1 --insufficient-data-actions ${SNS} --alarm-actions ${SNS}
	[[ $? -ne 0 ]] && Log_Msg Error "Failed to setup cloudwatch alarm" 1
	###BLOCK ENDS
fi
exit 0