#!/bin/bash

# Description: Master script to trigger all dependacy scripts
# Created on : Fri Aug 19 14:00:58 JST 2016
# Created by : prasanth_gv@amway.com
#

## Version Control
# 1.0 : Fri Aug 19 14:00:58 JST 2016 : Initial Version
# 2.0 : Fri Aug 19 14:00:58 JST 2016 : Added logic to obtain variables and set values based on VPC_ID

## Exit Codes
# 0   : Successful exit
# 1   : ScriptConfig.conf not found in the S3 build script path
# 2   : Failed to execute $script
# 3   : Failed to change directory to build path

## Following variables comes from the bootstrap script
#VPCID
#AutoScalingGroup
#S3Bucket
#Ec2InstanceRole
#Ec2TagName
#BuildScriptPath
#Environment
#APP
#SUBAPP
#AWSRegion
#Ec2SecurityGroup
#Ec2ElasticIPAllocationID
#TimeZone
#HTTPBuildPath
#AmwayLocation1
#AmwayLocation2

export BuildPath="/usr/local/BuildFiles"
export LogFile="${BuildPath}/BuildLog.log"

Log_Msg() {
	SEV=$1
	MSG=$2
	DATE_STR=$(date '+%Y%m%d:%H:%M:%S')
	if [ "x$LogFile" != "x" ]; then
		touch $LogFile
		echo "${DATE_STR}|${SEV}|${MSG}" | tee -a $LogFile
	else
		echo "${DATE_STR}|${SEV}|${MSG}"
	fi
	if [ $# -eq 3 ]; then
		exit "$3"
	fi
}

export -f Log_Msg

# Set AWS Region
aws configure set region $AWSRegion

# Set Variablaes
export INSTANCE_ID=$(/opt/aws/bin/ec2-metadata -i | awk '{print $2}')
export MAC_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
export HOST_IP_ADDR=$(ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2;}' | cut -d: -f2)
export VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${MAC_ADDRESS}/vpc-id/)
export MonitoringScript="${BuildScriptPath}/Common/Monitoring/CloudWatchMonitoringScripts-1.2.1-mem_utilization_fix.zip"
export INSTANCE_NAME=$(aws ec2 describe-tags --region=$AWSRegion --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" --output=text | cut -f5 | tr '[:upper:]' '[:lower:]')
export MailServerName="mail.mailrouter.net"
case "$VPC_ID" in
   "vpc-e485f481") 
		export RootEmail="APAC-AWS-OPS@Amway.com"
		export EnvValue="prd"
		export Jurisdiction="APAC"
		export VPC_Name="Apne1ApacPrd01"
		export DomainExtension="apac.amway.net"
		export SNS="arn:aws:sns:ap-northeast-1:002156193533:ApacPrdMonitoringAlerts"
		export SyslogServer="syslog.apac.amway.net"
		export Ad_Admin_Server="Null"
		export Ad_Server="Null"
		export Ad_Account=UXJAWSAD
		export Ad_Password=Dc5r3WTd
		export Ou_Path="Servers/Asia-Pac/AWS"
		export Remote_Access_Group="na-amw-it-apac.managementprdremoteaccess"
		export Remote_Priviliaged_Group="na-amw-it-apac.managementprdprivilege"
   ;;
   "vpc-3e7d0c5b") 
		export RootEmail="APAC-AWS-OPS@Amway.com"
		export EnvValue="dev"
		export Jurisdiction="APAC"
		export VPC_Name="Apne1ApacPreprod01"
		export DomainExtension="preprod.apac.amway.net"
		export SNS="arn:aws:sns:ap-northeast-1:141515744291:ApacPreprdMonitoringAlerts"
		export SyslogServer="syslog.preprod.apac.amway.net"
		export Ad_Admin_Server="Null"
		export Ad_Server="Null"
		export Ad_Account=UXJAWSAD
		export Ad_Password=Dc5r3WTd
		export Ou_Path="Servers/Asia-Pac/AWS"
		export Remote_Access_Group="na-amw-it-apac.managementdevremoteaccess"
		export Remote_Priviliaged_Group="na-amw-it-apac.managementdevprivilege"
   ;;
   "vpc-13702f76") 
		export RootEmail="SEA-AWS-OPS@Amway.com"
		export EnvValue="prd"
		export Jurisdiction="SEA"
		export VPC_Name="Apse1SeaPrd01"
		export DomainExtension="sea.amway.net"
		export SNS="arn:aws:sns:ap-southeast-1:825254135214:SeaPrdMonitoringAlerts"
		export SyslogServer="syslog.sea.amway.net"
		export Ad_Admin_Server="mycybedc03.na.intranet.msd"
		export Ad_Server="mycybedc03.na.intranet.msd,mycybedc04.na.intranet.msd"
		export Ad_Account=UXJAWSAD
		export Ad_Password=Dc5r3WTd
		export Ou_Path="Servers/Asia-Pac/AWS"
		export Remote_Access_Group="na-amw-it-sea.managementprdremoteaccess"
		export Remote_Priviliaged_Group="na-amw-it-sea.managementprdprivilege"
   ;;
   "vpc-a7075ec2") 
		#TO_CHANGE#export RootEmail="SEA-AWS-OPS@Amway.com"
		export RootEmail="Prasanth_GV@Amway.com"
		export EnvValue="dev"
		export Jurisdiction="SEA"
		export VPC_Name="Apse1SeaPreprod01"
		export DomainExtension="preprod.sea.amway.net"
		export SNS="arn:aws:sns:ap-southeast-1:183887352813:SeaPreprdMonitoringAlerts"
		export SyslogServer="syslog.preprod.sea.amway.net"
		export Ad_Admin_Server="mycybedc03.na.intranet.msd"
		export Ad_Server="mycybedc03.na.intranet.msd,mycybedc04.na.intranet.msd"
		export Ad_Account=UXJAWSAD
		export Ad_Password=Dc5r3WTd
		export Ou_Path="Servers/Asia-Pac/AWS"
		export Remote_Access_Group="na-amw-it-sea.managementdevremoteaccess"
		export Remote_Priviliaged_Group="na-amw-it-sea.managementdevprivilege"
   ;;
   "vpc-027e9b66") 
		export RootEmail="APAC-AWS-Arch-OPS@Amway.com"
		export EnvValue="dev"
		export Jurisdiction="SEA"
		export VPC_Name="Apse1ShaDev01"
		export DomainExtension="preprod.apac.amway.net"
		export SNS="arn:aws:sns:ap-northeast-1:336241729858:ApacRegionalArchitecture"
		export SyslogServer="syslog.preprod.apac.amway.net"
		export Ad_Admin_Server="Null"
		export Ad_Server="Null"
		export Ad_Account=UXJAWSAD
		export Ad_Password=Dc5r3WTd
		export Ou_Path="Servers/Asia-Pac/AWS"
		export Remote_Access_Group="na-amw-it-apac.managementprdremoteaccess"
		export Remote_Priviliaged_Group="na-amw-it-apac.managementprdprivilege"
   ;;   
   *) 
		export RootEmail="UNKNOWN"
		export EnvValue="UNKNOWN"
		export Jurisdiction="UNKNOWN"
		export VPC_Name="UNKNOWN"
		export DomainExtension="UNKNOWN"
		export SNS="UNKNOWN"
		export SyslogServer="UNKNOWN"
		export Ad_Admin_Server="UNKNOWN"
		export Ad_Server="UNKNOWN"
		export Ad_Account="UNKNOWN"
		export Ad_Password="UNKNOWN"
		export Ou_Path="Servers/Asia-Pac/AWS"
		export Remote_Access_Group="UNKNOWN"
		export Remote_Priviliaged_Group="UNKNOWN"
   ;; 
esac

#for script in `ls [0-9]*.sh|sort -n`;do
cd ${BuildPath} || Log_Msg Error "Failed to change directory to build path" 3
/usr/bin/curl ${HTTPBuildPath}/${Environment}/${Ec2TagName}/ScriptConfig.conf -O

[[ $? -ne 0 ]] && Log_Msg Error "$0 ScriptConfig.conf not found in the S3 build script path" 1

for script in $(cat ${BuildPath}/ScriptConfig.conf|grep .|grep -v '^#');do
	cd ${BuildPath} || Log_Msg Error "Failed to change directory to build path" 3
	/usr/bin/curl ${HTTPBuildPath}/${Environment}/${Ec2TagName}/${script} -O
	chmod u+x ${BuildPath}/$script
	Log_Msg Info "Executing $script"
	${BuildPath}/$script 
	if [ $? -ne 0 ]; then
		Log_Msg Error "Failed to execute $script"
		LANG="en_US.UTF-8" ; export LANG
		( echo "Instance ID: ${INSTANCE_ID}"; echo "Date: $(date)"; echo "Application Name: ${APP}"; echo "Sub Application Name: `echo ${SUBAPP} | cut -c2-`"; echo "VPC: ${Environment}/${Jurisdiction}/${VPC_Name}"; echo; echo "--------"; echo ; cat $LogFile; echo; cat /var/log/cloud-init-output.log )  | tee | strings | tr -d '\015' | mail -s "Instance build ${INSTANCE_NAME} failed in ${Environment}/${Jurisdiction}/${VPC_Name} at script ${script}: ${INSTANCE_ID}" $RootEmail
		Log_Msg Error "Failed to execute $script" 2
	fi
	Log_Msg Info "$script executed successfully"
done

# Send instance build email to TEG & TSG
LANG="en_US.UTF-8" ; export LANG
( echo "Instance ID: ${INSTANCE_ID}"; echo "Date: $(date)"; echo "Application Name: ${APP}"; echo "Sub Application Name: `echo ${SUBAPP} | cut -c2-`"; echo "VPC: ${Environment}/${Jurisdiction}/${VPC_Name}"; echo; echo "--------"; echo ; cat $LogFile; echo; cat /var/log/cloud-init-output.log )  | tee | strings | tr -d '\015' | mail -s "New ${INSTANCE_NAME} instance launched in ${Environment}/${Jurisdiction}/${VPC_Name}: ${INSTANCE_ID}" $RootEmail

Log_Msg Info "$0 executed successfully"
exit 0