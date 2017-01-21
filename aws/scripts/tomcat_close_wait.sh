#!/bin/bash

# Description: script to count close_wait connections of tomcat for port 443 and if close_wait exceeds 1000 then 1. executing pre-script to detach instance from elb,2. restarting tomcat,3. then executing post script to attach again to elb 
# Created on : Mon Jan 09 14:00:58 IST 2017
# Created by : ankit bhalla
#

## Version Control
# 1.0 : Mon Jan 09 14:00:58 IST 2017 : Initial Version


## Exit Codes
# 0   : Successful exit
# 1   : Script not found in the build script path
# 2   : Failed to execute $script
# 3   : Failed to change directory to build path
# 4   : Failed to find pre_script.sh
# 5   : Failed to find pre_script.sh
# 6   : Failed to execute pre_script.sh
# 7   : Failed to execute post_script.sh
# 8   : Failed exit



export BuildPath="/sscp/scripts"
export LogFile="${BuildPath}/logs/BuildLog.log"

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


# Set Variablaes
export INSTANCE_ID=$(/opt/aws/bin/ec2-metadata -i | awk '{print $2}')
export AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}')
#export MAC_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
#export HOST_IP_ADDR=$(ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2;}' | cut -d: -f2)
#export VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${MAC_ADDRESS}/vpc-id/)
#export INSTANCE_NAME=$(aws ec2 describe-tags --region=$AWSRegion --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" --output=text | cut -f5 | tr '[:upper:]' '[:lower:]')
export CLOSE_WAIT_COUNT=`netstat -ton | grep -i 443 | grep CLOSE_WAIT | wc -l`
export TOMCAT_HOME="/usr/share/tomcat/bin"
export PRE_SCRIPT_FILE="${TOMCAT_HOME}/pre_script.sh"
export POST_SCRIPT_FILE="${TOMCAT_HOME}/post_script.sh"
export TOMCAT_PID=`ps -ef | grep -i java | grep -v grep | awk 'NR==1{print $2}'`



cd ${BuildPath} || Log_Msg Error "Failed to change directory to build path" 3

if [ ${CLOSE_WAIT_COUNT} -eq 0 ]; then

	if [ ! -f ${PRE_SCRIPT_FILE} ]; then
		[[ $? -ne 0 ]] && Log_Msg Error "pre_script.sh not found in script path" 4
	else
		Log_Msg Info "Executing $script"
		sh ${PRE_SCRIPT_FILE}
		if [ $? -eq 0 ];then
			Log_Msg Info "Script successfully executed"
		else
			Log_Msg Error "Failed to execute $script" 6
		fi
	fi
	
	Log_Msg Info "Stopping Tomcat"
	TOMCAT_STATUS=`ps -ef | grep java | grep -v grep | awk '{print $2}'`
	if [ -n {TOMCAT_STATUS} ]; then
	cd ${TOMCAT_HOME}
        ./shutdown.sh
	sleep 5
        ps -p ${TOMCAT_PID}
        if [ $? != 0 ]
			then
				Log_Msg Info "\nTomcat process has been killed..."
		else
				Log_Msg Info "\nThere is some issue with Tomcat process, please kill manually...\nPID is $TOMCAT_PID"
				kill -9 ${TOMCAT_PID}
		fi
		
        Log_Msg Info "Tomcat Stopped"

        else
		Log_Msg Info "\nTomcat Already Stopped"
	fi
	
	Log_Msg Info "Starting Tomcat"
	#service tomcat start
	cd ${TOMCAT_HOME}
	./startup.sh 
	export TOMCAT_PID=`ps -ef | grep -i java | grep -v grep | awk 'NR==1{print $2}'`
	#echo -e $TOMCAT_PID
	if [ -z ${TOMCAT_PID} ];then
			Log_Msg Error "Tomcat failed to Start" 8
		else
		    Log_Msg Info "Tomcat started"
        fi	  

 sleep 6
	
	if [ ! -f ${POST_SCRIPT_FILE} ]; then
		[[ $? -ne 0 ]] && Log_Msg Error "post_script.sh not found in script path" 5
	else	
		Log_Msg Info "Executing Post Script"
		sh ${POST_SCRIPT_FILE}
		if [ $? -eq 0 ];then
		 	Log_Msg Info "Script Successfully executed"
		else
	 		Log_Msg Error "Failed to execute $script" 7
		fi
	fi

    Log_Msg Info "CLOSE_WAIT Loop executed successfully"
fi
	


Log_Msg Info "$0 executed successfully"
exit 0
