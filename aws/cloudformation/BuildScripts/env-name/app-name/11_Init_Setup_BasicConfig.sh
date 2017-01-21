#!/bin/bash

# Description: Script to install S3FS software
# Created on : Fri Aug 19 14:00:58 JST 2016
# Created by : ankit bhalla
#

## Version Control
# 1.0 : Fri Aug 19 14:00:58 JST 2016 : Initial Version
# 1.1 : Thu Aug 25 11:50:39 TST 2016 : Add syslog-ng basic configuration

## Exit Codes
# 0   : Successful exit
# 1   : Failed to set timezone
# 2   : Package installation/update/removal failed


# Set timezone
cat > /etc/sysconfig/clock << EOF
ZONE="$TimeZone"
UTC=false
EOF
ln -sf /usr/share/zoneinfo/$TimeZone /etc/localtime
[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to set timezone" 1


##Security Hardening

# Disabling ICMP redirection

grep "Demo - Security Hardening" /etc/sysctl.conf >/dev/null 2>&1
if [ $? -ne 0 ]; then
	cat >> /etc/sysctl.conf << EOF

### demo - Security Hardening

# Disabling ICMP redirection
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
EOF
/sbin/sysctl -p

fi

# Disable direct root login from terminal
cp -p /etc/securetty /etc/securetty.orig
> /etc/securetty

#Secure NFS folder
chmod 750 /var/lib/nfs

# Syslog & audit settings
sed -i 's/^active = no/active = yes/g' /etc/audisp/plugins.d/syslog.conf
sed -i 's/^weekly/daily/g' /etc/logrotate.conf
sed -i 's/^rotate 4/rotate 7/g' /etc/logrotate.conf
sed -i 's/^dateext/#dateext/g' /etc/logrotate.conf

# Adjust anacron for local log rotation at midnight
sed -i 's/^START_HOURS_RANGE=15-22/START_HOURS_RANGE=0-22/g' /etc/anacrontab
sed -i 's/^1\t25\tcron.daily/1\t00\tcron.daily/g' /etc/anacrontab

# Set audit rules
cat >> /etc/audit/audit.rules << EOF
-w /etc/audit/ -p wa -k CFG_audit
-w /etc/audisp/ -p wa -k CFG_audisp
-w /etc/group -p wa -k auth
-w /etc/passwd -p wa -k auth
-w /etc/gshadow -p wa -k auth
-w /etc/shadow -p wa -k auth
-w /etc/security/opasswd -p wa -k auth
-w /etc/ssh/sshd_config -k CFG_sshd_config
## sudo configuration
-w /etc/sudoers -k CFG_sudoers
-w /etc/sudoers.d/ -k CFG_sudoers
## xinetd configuration
-w /etc/xinetd.d/ -k CFG_xinetd.d
-w /etc/xinetd.conf -k CFG_xinetd.conf
## pam configuration
-w /etc/pam.d/ -p wa -k CFG_pam
-w /etc/security/access.conf -p wa  -k CFG_pam
-w /etc/security/limits.conf -p wa  -k CFG_pam
-w /etc/security/pam_env.conf -p wa -k CFG_pam
-w /etc/security/namespace.conf -p wa -k CFG_pam
-w /etc/security/namespace.d/ -p wa -k CFG_pam
-w /etc/security/namespace.init -p wa -k CFG_pam
-w /etc/security/sepermit.conf -p wa -k CFG_pam
-w /etc/security/time.conf -p wa -k CFG_pam
## system startup scripts
-w /etc/sysconfig/init -p wa -k CFG_init
-w /etc/init/ -p wa -k CFG_init
-w /etc/inittab -p wa -k CFG_inittab
-w /etc/rc.d/init.d/ -p wa -k CFG_initscripts
EOF

# List the SUID/SGID/WorldWrirable files/directory to a file for future reference
find / -perm -4000 -o -perm -2000 > /usr/local/SUIDSGID 2>&1
find / -perm -2 ! -type l -ls > /usr/local/WorldWritable 2>&1

# Add audit log rule to monitor the change to the above audit file.
cat >> /etc/audit/audit.rules << EOF
-w /usr/local/SUIDSGID -k CFG_SUIDSGID
-w /usr/local/WorldWritable -k CFG_WorldWritable
EOF

# Add essential tools (just in case)
yum -y install python
yum -y install wget

### RHEL 7 specific ###
if [ x`cat /etc/os-release  | grep ^ID=` == xID=\"rhel\" ]; then 
	
	# Install ec2-metadata tool
	mkdir -p /opt/aws/bin
	cd /opt/aws/bin
	wget http://s3.amazonaws.com/ec2metadata/ec2-metadata
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install ec2-metadata" 2
	chmod a+x ec2-metadata
	echo "PATH=\$PATH:/opt/aws/bin" >> /etc/profile.d/aws.sh
	source /etc/profile.d/aws.sh
	
	# Install aws cli tool
	cd /tmp
	curl -O https://bootstrap.pypa.io/get-pip.py
	python get-pip.py
	pip install awscli
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install awscli" 2
	
	# Install and enable NTP for RHEL
	yum -y install ntp
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install ntpd" 2
	systemctl enable ntpd.service
	systemctl start ntpd.service
	
	# Switch from rsylog to syslog-ng
	yum -y remove rsyslog
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to remove rsyslog" 2
	
	cd /tmp
	wget http://mirror.centos.org/centos/7/os/x86_64/Packages/libnet-1.1.6-7.el7.x86_64.rpm
	rpm -Uvh libnet-1.1.6-7.el7.x86_64.rpm
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to update libnet" 2
	wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	yum -y install epel-release-latest-7.noarch.rpm
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install epel repos" 2
	
	yum -y --enablerepo=epel install syslog-ng syslog-ng-libdbi
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install syslog-ng" 2
	
	systemctl enable syslog-ng.service
	systemctl start syslog-ng.service
	
	# Cleanup, reinstall cronie & dependencies (removed when rsylog was removed)
	yum -y install cronie
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install cronie" 2
	
### AWS Linux specific ###
elif [ x`cat /etc/os-release  | grep ^ID=` == xID=\"amzn\" ]; then

	# Switch from sendmail to postfix
	yum -y install postfix
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install postfix" 2
	service sendmail stop
	service postfix start
	alternatives --set mta /usr/sbin/sendmail.postfix
	chkconfig postfix on
	
	# Switch from rsyslog to syslog-ng
	yum -y remove rsyslog
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to remove rsyslog" 2
	yum -y --enablerepo=epel install syslog-ng syslog-ng-libdbi
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install syslogng" 2
	
	# Make sure syslog is configured to start on boot
	chkconfig syslog-ng on
	service syslog-ng start
	
	# Cleanup, reinstall cronie & dependencies (removed when rsylog was removed)
	yum -y install cronie
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to install cron" 2
	service crond start

fi

### Basic Syslog server settings
cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.orig
cat >> /etc/syslog-ng/syslog-ng.conf << EOF
####
@define ENV "$ENV"
@define InstanceID "$INSTANCE_ID"
@define App "$APP"
@define SyslogServer "$SyslogServer"
@define SubApp "$SUBAPP"
EOF

# Configure postfix
if [ x"`grep \#\#\#\ demo\ \-\ Custom\ Postfix /etc/postfix/main.cf`" == x ]; then
cat >> /etc/postfix/main.cf << EOF

### demo - Custom Postfix
myorigin = demo.com
relayhost = [$MailServerName]
sender_canonical_maps = hash:/etc/postfix/canonical
virtual_alias_maps = hash:/etc/postfix/virtual
EOF

fi
	
cat > /etc/postfix/canonical << EOF
root $RootEmail
root@localhost $RootEmail
root@localhost.localdomain $RootEmail
root@demo.com $RootEmail
EOF

TmpVal=$(echo $RootEmail|cut -d'@' -f1)
cat > /etc/postfix/virtual << EOF
root $TmpVal
root@demo.com $RootEmail
EOF

postmap /etc/postfix/virtual
postmap /etc/postfix/canonical
service postfix reload

# Update all packages. Disabled for time being
#yum -y upgrade

# Setup PreStopTermination service to execute codes (copy of logs etc.) before machine terminates/shutdown.
/usr/bin/aws s3 cp ${BuildScriptPath}/${Environment}/${Ec2TagName}/PreStopTermination ${BuildPath} 2>&1
if [ $? -eq 0 ]; then
	cp ${BuildPath}/PreStopTermination /etc/init.d
	sed -i "s/RootEmail=BLANK/RootEmail=$RootEmail/g" /etc/init.d/PreStopTermination
	sed -i "s/INSTANCE_ID=BLANK/INSTANCE_ID=$INSTANCE_ID/g" /etc/init.d/PreStopTermination
	sed -i "s/INSTANCE_NAME=BLANK/INSTANCE_NAME=$INSTANCE_NAME/g" /etc/init.d/PreStopTermination
	sed -i "s/APP=BLANK/APP=$APP/g" /etc/init.d/PreStopTermination
	sed -i "s/SUBAPP=BLANK/SUBAPP=$SUBAPP/g" /etc/init.d/PreStopTermination
	sed -i "s/Environment=BLANK/Environment=$Environment/g" /etc/init.d/PreStopTermination
	sed -i "s/Jurisdiction=BLANK/Jurisdiction=$Jurisdiction/g" /etc/init.d/PreStopTermination
	sed -i "s/VPC_Name=BLANK/VPC_Name=$VPC_Name/g" /etc/init.d/PreStopTermination
	chmod 500 /etc/init.d/PreStopTermination
	chkconfig PreStopTermination on
	service PreStopTermination start
fi

# Setup lifecycle hook for autoscaling group
if [ "x${AutoScalingGroup}" != "x" ];then
	/usr/bin/aws s3 cp ${BuildScriptPath}/${Environment}/${Ec2TagName}/TerminationHook.sh ${BuildPath} 2>&1
	if [ $? -eq 0 ]; then
		chmod 500 ${BuildPath}/TerminationHook.sh
		AutoScalingGroupName=$(aws autoscaling describe-auto-scaling-instances --output text --instance-ids=$INSTANCE_ID --query 'AutoScalingInstances[*].AutoScalingGroupName')
		HookExist=$(aws autoscaling describe-lifecycle-hooks --output text --auto-scaling-group-name  $AutoScalingGroupName  --query 'LifecycleHooks[*].LifecycleHookName')
		if [ "x$HookExist" != "TerminationHook" ]; then
			aws autoscaling put-lifecycle-hook --lifecycle-hook-name TerminationHook --auto-scaling-group-name $AutoScalingGroupName --lifecycle-transition autoscaling:EC2_INSTANCE_TERMINATING
		fi
		sed -i "s/AutoScalingGroupName=BLANK/AutoScalingGroupName=$AutoScalingGroupName/g" ${BuildPath}/TerminationHook.sh
		#sed -i "s/Ad_Account=BLANK/Ad_Account=$Ad_Account/g" ${BuildPath}/TerminationHook.sh
		#sed -i "s/Ad_Password=BLANK/Ad_Password=$Ad_Password/g" ${BuildPath}/TerminationHook.sh
		#sed -i "s/Ad_Admin_Server=BLANK/Ad_Admin_Server=$Ad_Admin_Server/g" ${BuildPath}/TerminationHook.sh
		sed -i "s/INSTANCE_ID=BLANK/INSTANCE_ID=$INSTANCE_ID/g" ${BuildPath}/TerminationHook.sh
		sed -i "s/AWSRegion=BLANK/AWSRegion=$AWSRegion/g" ${BuildPath}/TerminationHook.sh
		echo "*/1 * * * * root ${BuildPath}/TerminationHook.sh >/dev/null 2>&1" > /etc/cron.d/termination-hook	
		chmod 644 /etc/cron.d/termination-hook
		service crond reload
	fi
fi

if [ "x${AutoScalingGroup}" != "x" ];then
	/usr/bin/aws s3 cp ${BuildScriptPath}/${Environment}/${Ec2TagName}/PendingHook.sh ${BuildPath} 2>&1
	if [ $? -eq 0 ]; then
		chmod 500 ${BuildPath}/PendingHook.sh
		AutoScalingGroupName=$(aws autoscaling describe-auto-scaling-instances --output text --instance-ids=$INSTANCE_ID --query 'AutoScalingInstances[*].AutoScalingGroupName')
		HookExist=$(aws autoscaling describe-lifecycle-hooks --output text --auto-scaling-group-name  $AutoScalingGroupName  --query 'LifecycleHooks[*].LifecycleHookName')
		if [ "x$HookExist" != "PendingHook" ]; then
			aws autoscaling put-lifecycle-hook --lifecycle-hook-name PendingHook --auto-scaling-group-name $AutoScalingGroupName --lifecycle-transition autoscaling:EC2_INSTANCE_LAUNCHING
		fi
		sed -i "s/AutoScalingGroupName=BLANK/AutoScalingGroupName=$AutoScalingGroupName/g" ${BuildPath}/PendingHook.sh
		#sed -i "s/Ad_Account=BLANK/Ad_Account=$Ad_Account/g" ${BuildPath}/TerminationHook.sh
		#sed -i "s/Ad_Password=BLANK/Ad_Password=$Ad_Password/g" ${BuildPath}/TerminationHook.sh
		#sed -i "s/Ad_Admin_Server=BLANK/Ad_Admin_Server=$Ad_Admin_Server/g" ${BuildPath}/TerminationHook.sh
		sed -i "s/INSTANCE_ID=BLANK/INSTANCE_ID=$INSTANCE_ID/g" ${BuildPath}/PendingHook.sh
		sed -i "s/AWSRegion=BLANK/AWSRegion=$AWSRegion/g" ${BuildPath}/PendingHook.sh
		echo "*/1 * * * * root ${BuildPath}/TerminationHook.sh >/dev/null 2>&1" > /etc/cron.d/pending-hook	
		chmod 644 /etc/cron.d/pending-hook
		service crond reload
	fi
fi


# Add additional tools
yum -y install mlocate || Log_Msg Error "failed to install" 2
yum -y install strace || Log_Msg Error "failed to install" 2
yum -y install telnet || Log_Msg Error "failed to install" 2
yum -y install mailx || Log_Msg Error "failed to install" 2
yum -y install ftp || Log_Msg Error "failed to install" 2
yum -y install lsof || Log_Msg Error "failed to install" 2
yum -y install unzip || Log_Msg Error "failed to install" 2

exit 0