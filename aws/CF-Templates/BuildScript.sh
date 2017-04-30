#!/bin/bash

# Version Control
# 201512042033 : Adding option to update routes through scripting.
# 201512052030 : Added steps to remove and reattach ENI

## Setting Variables
AWS=/usr/bin/aws

### Temporary Variables to test the script.
#/usr/bin/aws s3 cp /tmp
#export VPCID=vpc-e044ce85
#export Ec2TagName=KorStgInfraOpenSwan01
#export Environment=Stg
#export VpcName=Apne1KorStg01
#export AWSRegion=ap-northeast-1
#export OpenSwanEipAllocationID=eipalloc-b1e341d4
#export OpenSwanSecurityGroup=sg-b7e9dfd2
#export TimeZone=Asia/Seoul
export Location1="${DestSubnetIDs:=NULL}"
export Location2="${DestVPCSubnetCIDR:=NULL}"
#export Location2="172.16.0.0/12"
#export PAPublicIP1="${OpenSwanEIP:=NULL}"
#export PAPublicIP2="52.69.124.223"
#export PATunnelPssword1="KoreaProdVPC"
#export PATunnelPssword2="KoreaProdVPC"


Ec2InstanceID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
Ec2InstanceID=${Ec2InstanceID:=Null}
OpenSwanEIP=$($AWS ec2 describe-addresses --allocation-ids $OpenSwanEipAllocationID --region $AWSRegion --query 'Addresses[*].PublicIp' --output text)
VpcCIDR=$($AWS ec2 describe-vpcs --vpc-ids $VPCID --region $AWSRegion --query 'Vpcs[*].CidrBlock' --output text)


echo "Script $0 is being executed"

Log_Msg() {
    SEV=$1
    MSG=$2
 ACT=$3
    DATE_STR=$(date '+%Y%m%d:%H:%M:%S')
    echo "${DATE_STR}|${SEV}|${MSG}"
 logger -- "$(basename $0) - ${SEV}|${MSG}"
 ACT=${ACT:=0}
 if [ $ACT -ne 0 ]; then
  exit $ACT
 fi
}

UpdateRoutes() {
 RouteTableList=$($AWS ec2 describe-route-tables --region $AWSRegion --filters "Name=tag:Environment,Values=$Environment" "Name=vpc-id,Values=$VPCID" --query 'RouteTables[*].RouteTableId' --output text)
 RouteTableList=${RouteTableList:=Null}
 for Location in $Location2;do
  for RouteTable in $RouteTableList;do
   $AWS ec2 describe-route-tables --region $AWSRegion --route-table-ids $RouteTable --query 'RouteTables[*].Routes[*].DestinationCidrBlock' --output text|grep $Location >/dev/null
   if [ $? -eq 0 ];then
    $AWS ec2 replace-route --route-table-id $RouteTable --destination-cidr-block $Location --network-interface-id  $NewNetworkInterfaceID --region $AWSRegion
    retcode=$?
    [[ "$retcode" -ne 0 ]] && Log_Msg Error "Failed to update the route on $RouteTable with new route device $NewNetworkInterfaceID"  1
    Log_Msg Info "Successfully updated Route on $RouteTable with new route device $NewNetworkInterfaceID"
   else
    $AWS ec2 create-route --route-table-id $RouteTable --destination-cidr-block $Location --network-interface-id  $NewNetworkInterfaceID --region $AWSRegion
    retcode=$?
    [[ "$retcode" -ne 0 ]] && Log_Msg Error "Failed to update the route on $RouteTable with new route device $NewNetworkInterfaceID"  1
    Log_Msg Info "Successfully created new Route on $RouteTable with new route device $NewNetworkInterfaceID"
   fi
  done
 done
}

ChangeTimeZone() {
 Log_Msg Info "Chaging timezone of the system to $TimeZone"
 sed -i.cloudinit '/ZONE/d;/UTC/d' /etc/sysconfig/clock
 echo "ZONE=\"$TimeZone\"">>/etc/sysconfig/clock
 echo "UTC=false">>/etc/sysconfig/clock
 sudo ln -sf /usr/share/zoneinfo/$TimeZone /etc/localtime
 Log_Msg Info "Completed timezone change"
}

UpdateIpsec() {
 Log_Msg Info "Deploying IPSec configuraiton"
 echo "include /etc/ipsec.d/*.conf" >> /etc/ipsec.conf
 echo "conn Tunnel1
 dpddelay=5
 dpdtimeout=5
 dpdaction=restart
 ike=aes256-sha1;modp2048
 phase2=esp
 phase2alg=aes256-sha1;modp2048
 ikelifetime=8h
 authby=secret
 rekey=yes
 type=tunnel
 salifetime=1h
 pfs=yes
 aggrmode=no
 left=$OpenSwanPrivateIP
 leftid=$OpenSwanEIP
 leftsubnet=$VpcCIDR
 right=$PAPublicIP1
 rightsubnets={$Location1}
 auto=start" > /etc/ipsec.d/Tunnel1.conf
 echo "$OpenSwanEIP $PAPublicIP1: PSK \"$PATunnelPssword1\"" > /etc/ipsec.d/Tunnel1.secrets
 echo "conn Tunnel1
 dpddelay=5
 dpdtimeout=5
 dpdaction=restart
 ike=aes256-sha1;modp2048
 phase2=esp
 phase2alg=aes256-sha1;modp2048
 ikelifetime=8h
 authby=secret
 rekey=yes
 type=tunnel
 salifetime=1h
 pfs=yes
 aggrmode=no
 left=$OpenSwanPrivateIP
 leftid=$OpenSwanEIP
 leftsubnet=$VpcCIDR
 right=$PAPublicIP2
 rightsubnets={$Location1}
 auto=start" > /etc/ipsec.d/Tunnel2.conf.DISABLED
 
 echo "$OpenSwanEIP $PAPublicIP2: PSK \"$PATunnelPssword2\"" > /etc/ipsec.d/Tunnel2.secrets.DISABLED
 
 echo "# Openswan entries
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
 /sbin/sysctl -p
for f in /proc/sys/net/ipv4/conf/*/send_redirects; do echo 0 > $f; done
for f in /proc/sys/net/ipv4/conf/*/accept_redirects; do echo 0 > $f; done
 Log_Msg Info "Completed IPSec configuration"
}

EnableIpsec() {
 /sbin/chkconfig ipsec on
 /sbin/service ipsec restart
}

AttachEni() {
 OldNetworkInterfaceID=$($AWS ec2 describe-addresses --allocation-ids $OpenSwanEipAllocationID --region $AWSRegion --query 'Addresses[*].NetworkInterfaceId' --output text)
 OldNetworkInterfaceID=${OldNetworkInterfaceID:=Null}
 if [ "x$OldNetworkInterfaceID" != "xNull" ]; then
  Log_Msg Info "Old network is attached, detaching it first"
  OldNetworkInterfaceAssociationID=$($AWS ec2 describe-addresses --allocation-ids $OpenSwanEipAllocationID --region $AWSRegion --query 'Addresses[*].AssociationId' --output text)
  OldNetworkInterfaceAssociationID=${OldNetworkInterfaceAssociationID:=Null}
  OldInstanceID=$($AWS ec2 describe-network-interfaces --network-interface-ids $OldNetworkInterfaceID --region $AWSRegion --query 'NetworkInterfaces[*].Attachment.InstanceId' --output text)
  OldInstanceID=${OldInstanceID:=Null}
  Log_Msg Info "Detected allocation ID $OldNetworkInterfaceAssociationID, detaching EIP from ENI"
  $AWS ec2 disassociate-address --association-id $OldNetworkInterfaceAssociationID --region $AWSRegion
  retcode=$?
  [[ "$retcode" -ne 0 ]] && Log_Msg Error "Disassociation of Eni Failed" 1
  Log_Msg Info "Disassociation of Eni Successful"

  if [ "x$OldInstanceID" != "xNull" ]; then
   Log_Msg Info "Interface is attached to instance $OldInstanceID. Detaching it first".
   OldInstanceAttachmentId=$($AWS ec2 describe-network-interfaces --network-interface-ids $OldNetworkInterfaceID --region $AWSRegion --query 'NetworkInterfaces[*].Attachment.AttachmentId' --output text)
   OldInstanceAttachmentId=${OldInstanceAttachmentId:=Null}
   $AWS ec2  detach-network-interface --attachment-id $OldInstanceAttachmentId --region $AWSRegion
   retcode=$?
   [[ "$retcode" -ne 0 ]] && Log_Msg Error "Detachment of $OldNetworkInterfaceAssociationID from $OldInstanceID failed" 1
   Log_Msg Info "Detached $OldNetworkInterfaceAssociationID from $OldInstanceID"
  fi
  while true; do
   TmpValue=$($AWS ec2 describe-network-interfaces --network-interface-ids $OldNetworkInterfaceID --region $AWSRegion --query 'NetworkInterfaces[*].Attachment.AttachmentId' --output text)
   if [ "x$TmpValue" == "x" ];then
    break
   fi
   sleep 1
  done
  $AWS ec2 delete-network-interface --network-interface-id $OldNetworkInterfaceID --region $AWSRegion
  retcode=$?
  [[ "$retcode" -ne 0 ]] && Log_Msg Error "Deletion of Network Interface $OldNetworkInterfaceID failed" 1
  Log_Msg Info "Successfully deleted Network Interface $OldNetworkInterfaceID"
 fi


 OpenSwanSubnet=$($AWS ec2 describe-instances --instance-id $Ec2InstanceID --region $AWSRegion --query 'Reservations[*].Instances[*].SubnetId' --output text)
 OpenSwanSubnet=${OpenSwanSubnet:=Null}
 RandomString=$(date|md5sum|cut -d' ' -f1)
 $AWS ec2 create-network-interface --subnet-id $OpenSwanSubnet --groups $OpenSwanSecurityGroup --description "${Ec2TagName}_${RandomString}" --region $AWSRegion
 retcode=$?
 [[ "$retcode" -ne 0 ]] && Log_Msg Error "Failed Creating New ENI under $OpenSwanSubnet" 1
 Log_Msg Info "Successfully Created New ENI under $OpenSwanSubnet"
 NewNetworkInterfaceID=$( /usr/bin/aws ec2 describe-network-interfaces --region $AWSRegion --filters "Name=description,Values=${Ec2TagName}_${RandomString}" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text)
 NewNetworkInterfaceID=${NewNetworkInterfaceID:=Null}
 
 Log_Msg Info "Disabling Source/Dest. check of the interface $NewNetworkInterfaceID"
 $AWS ec2 modify-network-interface-attribute --no-source-dest-check --network-interface-id $NewNetworkInterfaceID --region $AWSRegion
 retcode=$?
 [[ "$retcode" -ne 0 ]] && Log_Msg Error "Disabling Source/Dest. check on $NewNetworkInterfaceID failed" 1
 Log_Msg Info "Successfully disabled Source/Dest. check on $NewNetworkInterfaceID"
 
 $AWS ec2 associate-address --allow-reassociation --allocation-id $OpenSwanEipAllocationID --network-interface-id $NewNetworkInterfaceID --region $AWSRegion
 retcode=$?
 [[ "$retcode" -ne 0 ]] && Log_Msg Error "EIP association to New ENI $NewNetworkInterfaceID failed" 1
 Log_Msg Info "Mapped the EIP to New ENI NewNetworkInterfaceID"
 $AWS ec2 attach-network-interface  --network-interface-id $NewNetworkInterfaceID --instance-id $Ec2InstanceID  --device-index 1 --region $AWSRegion
 retcode=$?
 [[ "$retcode" -ne 0 ]] && Log_Msg Error "Failed to attach the Interface" 1
 Log_Msg Info "Attached the new network interface $NewNetworkInterfaceID to instance $Ec2InstanceID"
 OpenSwanPrivateIP=$($AWS ec2  describe-network-interfaces --network-interface-ids $NewNetworkInterfaceID --region $AWSRegion --query 'NetworkInterfaces[*].PrivateIpAddress' --output text)
 Log_Msg Info "New interface private IP address is $OpenSwanPrivateIP"
 export OpenSwanPrivateIP
 
}

InstallPackages() {

 Log_Msg Info "Installing packages"
 yum update -d 0 -y
 sleep 2
 yum install -d 0 -y openswan
}

DisableInterface() {
# Following block can't *be used as device index with 0 cannot be detached form the system. Rather we would just disable the interface.
# FirstEni=$($AWS ec2 describe-network-interfaces --filters "Name=attachment.instance-id,Values=${Ec2InstanceID}" "Name=attachment.device-index,Values=0" --query 'NetworkInterfaces[*].NetworkInterfaceId' --region $AWSRegion --output text)
# FirstEniAttachmentId=$($AWS ec2 describe-network-interfaces --filters "Name=attachment.instance-id,Values=${Ec2InstanceID}" "Name=attachment.device-index,Values=0" --query 'NetworkInterfaces[*].Attachment.AttachmentId' --region $AWSRegion --output text)
# Log_Msg Info "Detaching First Interface $FirstEni from the system $Ec2InstanceID"
# $AWS ec2  detach-network-interface --attachment-id $FirstEniAttachmentId --region $AWSRegion
# retcode=$?
# [[ "$retcode" -ne 0 ]] && Log_Msg Error "Failed to Detach the interface $FirstEni from the system $Ec2InstanceID" 1
# Log_Msg Info "Successfully detached the interface $FirstEni from the system $Ec2InstanceID"
# Log_Msg Info "Deleting First Interface $Ec2InstanceID from the system $Ec2InstanceID"
# $AWS ec2 delete-network-interface --network-interface-id $FirstEni --region $AWSRegion
# retcode=$?
# [[ "$retcode" -ne 0 ]] && Log_Msg Error "Failed to Delete the interface $FirstEni" 1
# Log_Msg Info "Successfully deleted the interface $FirstEni"
###
 Log_Msg Info "Disabling the first interface"
    sed -i.cloudinit 's/ONBOOT.*/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
 
echo "
#!/bin/sh

# Script to disable primary network interface

start() {
        /sbin/ifdown eth0
}

# do it
case "\$1" in
    start|--start)
         start
         ;;
    *)
         echo "Incorrect Usage"
         RETVAL=2
esac

exit \$RETVAL" > /etc/init.d/ShutdownEth0
chmod 755 /etc/init.d/ShutdownEth0
ln -s /etc/init.d/ShutdownEth0 /etc/rc3.d/S45ShutdownEth0
 
 /sbin/ifdown eth0
 Log_Msg Info "Successfully completed disabling the first interface"
}

### Body Starts here
InstallPackages
AttachEni
UpdateRoutes
ChangeTimeZone
UpdateIpsec
EnableIpsec
DisableInterface

## Reboot the system
Log_Msg Info "Rebooting the system now"
/sbin/reboot