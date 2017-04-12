#!/bin/bash

#!/bin/bash
#
# Description: Any applicaiton post install tasks such as, configure applciation access, log monitoring etc.
# Created on : Fri Aug 19 14:00:58 JST 2016
# Created by : prasanth_gv@amway.com
#

## Version Control
# 1.0 : Fri Aug 19 14:00:58 JST 2016 : Initial Version

## Exit Codes
# 0   : Successful exit
# 15  : Failed to update /etc/sudoers.d/mgmt-privilege
# 16  : Failed to reload service sshd with error code



#Set Variables
App_Remote_Access_Group="na-amw-it-sea.managementprdremoteaccess"
App_Remote_Priviliaged_Group="na-amw-it-sea.managementprdprivilege"
App_Sudo_User_Name="test-user"


# Configure ssh to use AD groups for access control - NOTE: group names must be lower-case to match!!
# Proceed only if an app group is defined
if [ "x$App_Remote_Access_Group" != x ]; then
CurrConfig=$(grep '^AllowGroups' /etc/ssh/sshd_config)
if [ "x${CurrConfig}" != "x" ]; then
	NewConfig="$CurrConfig $App_Remote_Access_Group"
	sed -i_$(date '+%Y%m%d%H%M%S') "s/$CurrConfig/$NewConfig/g" /etc/ssh/sshd_config
else
cat >>  /etc/ssh/sshd_config << EOF
# Allow members of management remote access group to SSH to instance (and ec2-user group as backup)
AllowGroups ec2-user $App_Remote_Access_Group
EOF
fi	
fi

# Configure sudo to use AD groups for priv escalation - NOTE: group names must be lower-case to match!!
if [ "x$App_Remote_Priviliaged_Group" != x ]; then
 cat >> /etc/sudoers.d/app-privilege << EOF
# Allow application members to access application account
%$App_Remote_Priviliaged_Group ALL=($App_Sudo_User_Name) ALL
EOF
[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to update /etc/sudoers.d/mgmt-privilege" 15
fi

service sshd reload
[[ $? -ne 0 ]] &&  Log_Msg Error "$0 Failed to reload service sshd with error code $?" 16

exit 0

