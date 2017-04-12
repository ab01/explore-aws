#!/bin/bash -x
 
### Script to build Hybris
### Created by : Ankit.Bhalla@amway.com
### Version Control
# 20160425 : Initial Version
 
#Environment=$1
#TimeZone=$1
#BucketName=$2
AppsVersion=1.0
#Role=$3
#MasterCoreUrl=$4
#ENV=$4
#Package=$5
 
Log_Msg() {
    SEV=$1
    MSG=$2
    DATE_STR=$(date '+%Y%m%d:%H:%M:%S')
    echo "${DATE_STR}|${SEV}|${MSG}"
}
 
#if [ $# -ne 2 ]; then
 #   Log_Msg Eror "Missing Command line argument"
  #  exit 1
#fi
 
 ChangeTimeZone() {
 RC=0
	Log_Msg Info "Chaging timezone of the system to $TimeZone"
        sudo rm /etc/localtime
        sed -i.cloudinit '/ZONE/d;/UTC/d' /etc/sysconfig/clock
        echo "ZONE=\"$TimeZone\"">>/etc/sysconfig/clock
        echo "UTC=false">>/etc/sysconfig/clock
        sudo ln -sf /usr/share/zoneinfo/$TimeZone /etc/localtime
        Log_Msg Info "Completed timezone change"
	
	if [ $RC -ne 0 ];then
        Log_Msg Eror "TimeZone Creation Failed"
        exit 1
    fi
}
 
 
CreateUser() {
    RC=0
 
    /usr/sbin/groupadd hybris
    RC=$(($RC+$?))
    /usr/sbin/useradd -d /home/hybris -s /bin/bash -g hybris hybris
    RC=$(($RC+$?))
 
    if [ $RC -ne 0 ];then
        Log_Msg Eror "User Creation Failed"
        exit 1
    fi
}
 
DownloadResources() {
    RC=0
 
    mkdir -p /tmp/${AppsVersion}
    RC=$(($RC+$?))
    cd /tmp/${AppsVersion} && aws s3 sync s3://${BucketName}/${ENV}/${SUBAPP}/  . 
    RC=$(($RC+$?))
 
    if [ $RC -ne 0 ];then
        Log_Msg Eror "Failed to Download Resources"
        exit 1
    fi
}
 
DeployJava() {
    RC=0
 
    cd /tmp/${AppsVersion}/java && test "75e2fff2ed161c7de293c4408be8da8f2282b07b" = `sha1sum jdk-8u45-linux-x64.tar.gz | cut -b -40`
    RC=$(($RC+$?))
    mkdir /usr/java
    RC=$(($RC+$?))
    tar xzf jdk-8u45-linux-x64.tar.gz -C /usr/java
    RC=$(($RC+$?))
    cd /usr/java && chown -R root:root ./jdk1.8.0_45
    RC=$(($RC+$?))
    ln -s /usr/java/jdk1.8.0_45 latest
    RC=$(($RC+$?))
    ln -s /usr/java/latest default
    RC=$(($RC+$?))
    cd /tmp && rm -f jdk-8u45-linux-x64.tar.gz
    RC=$(($RC+$?))
	/usr/sbin/alternatives --install /usr/bin/java java /usr/java/default/bin/java 20000
	 RC=$(($RC+$?))
	 export JAVA_HOME=/usr/java/default
      RC=$(($RC+$?))
	  
    if [ $RC -ne 0 ];then
        Log_Msg Eror "Failed to Deploy Java"
        exit 1
    fi
}
  
 
 DeployCodeDeployAgent() {
   cd /home/ec2-user/
   RC=$(($RC+$?))	
   /usr/bin/aws s3 cp 's3://aws-codedeploy-ap-southeast-1/latest/codedeploy-agent.noarch.rpm' . 
	RC=$(($RC+$?))	
	rpm -ivh codedeploy-agent.noarch.rpm 
	RC=$(($RC+$?))	
	
	  if [ $RC -ne 0 ];then
        Log_Msg Eror "Failed to Deploy CodeDeploy Agent"
        exit 1
    fi
	}

CreateHybrisDirectory() {
   cd /home/hybris/	
   mkdir -p /home/hybris/backup
   RC=$(($RC+$?))	
   mkdir -p /home/hybris/scripts
   RC=$(($RC+$?))	
   mkdir -p /home/hybris/updates
   RC=$(($RC+$?))
   mkdir -p /data/buildfiles
   RC=$(($RC+$?))
   
    if [ $RC -ne 0 ];then
        Log_Msg Eror "Failed to Create Directory structure"
        exit 1
    fi
  } 
	
Log_Msg Info "ChangeTimeZone Started"	
ChangeTimeZone
Log_Msg Info "Completed ChangeTimeZone"

Log_Msg Info "Started CreateUser"
CreateUser
Log_Msg Info "Completed CreateUser"
 
Log_Msg Info "Started DownloadResources"
DownloadResources
Log_Msg Info "Completed DownloadResources"
 
Log_Msg Info "Started DeployJava"
DeployJava
Log_Msg Info "Completed DeployJava"

Log_Msg Info "Started CodeDeploy"
DeployCodeDeployAgent
Log_Msg Info "Completed CodeDeploy"

Log_Msg Info "Started CreateHybrisDirectory"
CreateHybrisDirectory
Log_Msg Info "Completed CreateHybrisDirectory"
 

