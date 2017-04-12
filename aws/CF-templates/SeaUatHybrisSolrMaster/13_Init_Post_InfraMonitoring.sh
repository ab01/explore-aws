#!/bin/bash

# Description: Script for setting up monitoirng for basic infra components
# Created on : Fri Aug 19 14:00:58 JST 2016
# Created by : prasanth_gv@amway.com
# Monitors follwoing parameters
# 1. CPU
# 2. Memory
# 3. Disk Usage

## Version Control
# 1.0 : Fri Aug 19 14:00:58 JST 2016 : Initial Version

## Exit Codes
# 0   : Successful exit
# 1   : Failed to install package
# 2   : Failed to setup cloudwatch alarm
# 3   : Failed to get cloudwatch custom monitoring script
# 4   : Failed to reload cron configuraiton


# Reload SSH to pick up any application-specific customizations
yum -y install unzip

if [ x$INSTANCE_ID != x ] && [ x$INSTANCE_NAME != x ] && [ "$SNS" != "UNKNOWN" ]; then

	### CPU ###
	
	# Set up warning & critical alarms for CPU
	aws cloudwatch put-metric-alarm --region=$AWSRegion --alarm-name ${INSTANCE_NAME}-${INSTANCE_ID}-CPUWarning --alarm-description "Warning - CPU utilization 95% or higher for 5 minutes" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 95 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=InstanceId,Value=${INSTANCE_ID} --evaluation-periods 1 --alarm-actions ${SNS} --unit Percent
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed setup cloudwatch alarm" 2
	
	aws cloudwatch put-metric-alarm --region=$AWSRegion --alarm-name ${INSTANCE_NAME}-${INSTANCE_ID}-CPUCritical --alarm-description "Critical - CPU utilization 95% or higher for 15 minutes" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 95 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=InstanceId,Value=${INSTANCE_ID} --evaluation-periods 3 --alarm-actions ${SNS} --insufficient-data-actions ${SNS} --unit Percent
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed setup cloudwatch alarm" 2
	
	### Disk & Memory ###
	
	# Set up metric collection for each filesystem
	yum install -y perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install perl" 1
	cd /usr/local/
	/usr/bin/aws s3 cp $MonitoringScript . >> /tmp/error.log
	echo "downloading $MonitoringScript"  >> /tmp/error.log
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to get cloudwatch custom monitoring script" 3
	unzip -o CloudWatchMonitoringScripts-1.2.1-mem_utilization_fix.zip
	chmod a+x /usr/local/aws-scripts-mon/*.pl
	rm -f CloudWatchMonitoringScripts-1.2.1-mem_utilization_fix.zip
	
	# Filter mount points for filesystems from block devices only
	VOLUMES=`mount  | grep -E '/dev/xvd|/dev/hs|/dev/sd'`
	VOLUME_PATHS=`echo "$VOLUMES" | awk '{print $3}' | sed 's/^/--disk-path=/' | paste -d" " -s -`
	
	# Set cron job
	echo "*/5 * * * * root /usr/local/aws-scripts-mon/mon-put-instance-data.pl --disk-space-util ${VOLUME_PATHS} --mem-util --from-cron" > /etc/cron.d/awscloudwatch-disk-mem	
	chmod 644 /etc/cron.d/awscloudwatch-disk-mem
	
	# Reload cron
	service crond start
	service crond reload
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to reload cron configuraiton" 4
	
	# Set up warning & critical alarms for each filesystem device
	echo "$VOLUMES" | while read line; do
		VOLUME_PATH=`echo $line | awk '{print $3}'`
		VOLUME_DEVICE=`echo $line | awk '{print $1}'`
		
		aws cloudwatch put-metric-alarm --region=$AWSRegion --alarm-name ${INSTANCE_NAME}-${INSTANCE_ID}-${VOLUME_PATH}-DiskWarning --alarm-description "Warning - Disk utilization 80% or higher" --metric-name DiskSpaceUtilization --namespace System/Linux --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=Filesystem,Value=${VOLUME_DEVICE} Name=InstanceId,Value=${INSTANCE_ID} Name=MountPath,Value=${VOLUME_PATH} --evaluation-periods 1 --alarm-actions ${SNS} --unit Percent
		[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed setup cloudwatch alarm" 2

		aws cloudwatch put-metric-alarm --region=$AWSRegion --alarm-name ${INSTANCE_NAME}-${INSTANCE_ID}-${VOLUME_PATH}-DiskCritical --alarm-description "Critical - Disk utilization 90% or higher" --metric-name DiskSpaceUtilization --namespace System/Linux --statistic Average --period 300 --threshold 90 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=Filesystem,Value=${VOLUME_DEVICE} Name=InstanceId,Value=${INSTANCE_ID} Name=MountPath,Value=${VOLUME_PATH} --evaluation-periods 1 --alarm-actions ${SNS} --insufficient-data-actions ${SNS} --unit Percent
		[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed setup cloudwatch alarm" 2
	done
	# Set up warning & critical alarms for memory
	aws cloudwatch put-metric-alarm --region=$AWSRegion --alarm-name ${INSTANCE_NAME}-${INSTANCE_ID}-MemoryWarning --alarm-description "Warning - Memory utilization 80% or higher" --metric-name MemoryUtilization --namespace System/Linux --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=InstanceId,Value=${INSTANCE_ID} --evaluation-periods 1 --alarm-actions ${SNS} --unit Percent
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed setup cloudwatch alarm" 2
	
	aws cloudwatch put-metric-alarm --region=$AWSRegion --alarm-name ${INSTANCE_NAME}-${INSTANCE_ID}-MemoryCritical --alarm-description "Critical - Memory utilization 90% or higher" --metric-name MemoryUtilization --namespace System/Linux --statistic Average --period 300 --threshold 90 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=InstanceId,Value=${INSTANCE_ID} --evaluation-periods 1 --alarm-actions ${SNS} --insufficient-data-actions ${SNS} --unit Percent
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed setup cloudwatch alarm" 2
	
fi

exit 0