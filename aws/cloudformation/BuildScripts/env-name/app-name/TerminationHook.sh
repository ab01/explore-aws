#!/bin/bash
#
# Description: This shell which runs in cron and triggers every 1 min. This script will execute the code block when it finds the life cycle trigger occurs
# Created on : Fri Aug 19 14:00:58 JST 2016
# Created by : prasanth_gv@amway.com
#

## Version Control
# 1.0 : Fri Aug 19 14:00:58 JST 2016 : Initial Version

AutoScalingGroupName=BLANK
#Ad_Account=BLANK
#Ad_Password=BLANK
#Ad_Admin_Server=BLANK
INSTANCE_ID=BLANK
AWSRegion=BLANK

# Set AWS Region
aws configure set region $AWSRegion

LifecycleState=$(aws autoscaling describe-auto-scaling-instances --output text --instance-ids=$INSTANCE_ID --query 'AutoScalingInstances[*].LifecycleState')

if [ $LifecycleState == "Terminating:Wait" ]; then
	echo "Triggering Mail for lifecycle hook execution $INSTANCE_ID" | mailx -s "Triggering Mail for lifecycle hook execution $INSTANCE_ID" ankitbhalla01@gmail.com
	#echo $Ad_Password | net ads leave -k -U $Ad_Account -S $Ad_Admin_Server
	/usr/bin/aws s3 cp /usr/share/tomcat/logs/catalina.out s3://asg-lifecyclehook-test/logs/
	######START Add additional code block you would like to execute before machine terminates
	#
	######END Add additional code block you would like to execute before machine terminates
	
	# Giving go signal to autoscaling group to terminate the instance
	aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id $INSTANCE_ID --lifecycle-hook-name TerminationHook --auto-scaling-group-name $AutoScalingGroupName
##	aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id $INSTANCE_ID --lifecycle-hook-name TerminationHook --auto-scaling-group-name $AutoScalingGroupName
fi

	
