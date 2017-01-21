#!/bin/bash

# Description: Script to install S3FS software
# Created on : Fri Aug 19 14:00:58 JST 2016
# Created by : ankit bhalla
#

## Version Control
# 1.0 : Fri Aug 19 14:00:58 JST 2016 : Initial Version

## Exit Codes
# 0   : Successful exit
# 1   : Failed to set timezone
# 2   : Package installation/update/removal failed


### RHEL 7 specific ###
if [ x`cat /etc/os-release  | grep ^ID=` == xID=\"rhel\" ]; then 
	# Change hostname (change domain to .apac.demo.net for production)
	sed -e '/ - set_hostname/ s/^#*/#/' -i /etc/cloud/cloud.cfg
	sed -e '/ - update_hostname/ s/^#*/#/' -i /etc/cloud/cloud.cfg

### AWS Linux specific ###
elif [ x`cat /etc/os-release  | grep ^ID=` == xID=\"amzn\" ]; then
	# Change hostname
	sed -e 's/HOSTNAME=.*/HOSTNAME='$INSTANCE_ID.$DomainExtension'/' -i /etc/sysconfig/network
	# Make hostname active now
	hostname $INSTANCE_ID.$DomainExtension

	# Add hostname to /etc/hosts
	FULL_HOSTNAME=$(grep HOSTNAME /etc/sysconfig/network | awk -F "=" '{print $2}')
	SHORT_HOSTNAME=$(echo $FULL_HOSTNAME |  awk -F "." '{print $1}')
	echo "127.0.0.1 $SHORT_HOSTNAME $FULL_HOSTNAME localhost localhost.localdomain" > /etc/hosts

fi

# Required for  a number of applications (e.g. Tomcat/TomEE), because hostname currently won't reverse lookup via DNS
echo -e "${HOST_IP_ADDR}\\t${SHORT_HOSTNAME}" >> /etc/hosts

exit 0
