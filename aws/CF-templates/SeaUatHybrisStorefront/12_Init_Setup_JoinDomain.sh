#!/bin/bash

#!/bin/bash
#
# Description: Script to join the node in domain
# Created on : Fri Aug 19 14:00:58 JST 2016
# Created by : prasanth_gv@amway.com
#

## Version Control
# 1.0 : Fri Aug 19 14:00:58 JST 2016 : Initial Version

## Exit Codes
# 0   : Successful exit
# 4   : Failed to install package
# 5   : Failed to enable  oddjobd service
# 6   : Failed to update /etc/krb5.conf
# 7   : Failed to update /etc/samba/smb.conf
# 8   : Failed to update /etc/sssd/sssd.conf
# 9   : Failed to join domain
# 10  : Failed to start service sssd with error code
# 11  : Failed to enable sssd service
# 12  : Failed to update /etc/pam.d/system-auth-ac
# 13  : Failed to update /etc/pam.d/password-auth-ac
# 14  : Failed to update /etc/ssh/sshd_config
# 15  : Failed to update /etc/sudoers.d/mgmt-privilege
# 16  : Failed to reload service sshd with error code



	
for pkg in krb5-workstation oddjob oddjob-mkhomedir samba4 sssd; do
	yum -y install $pkg
	[[ $? -ne 0 ]] && Log_Msg Error "$0 failed to install package $pkg" 4
done

##Start oddjobd service
service oddjobd start
# RHEL 7 specific
if [ x`cat /etc/os-release  | grep ^ID=` == xID=\"rhel\" ]; then 
	systemctl enable oddjobd.service;
	[[ $? -ne 0 ]] && Log_Msg Error "$0 failed to enable  oddjobd service" 5
# AWS Linux specific
elif [ x`cat /etc/os-release  | grep ^ID=` == xID=\"amzn\" ]; then 
	chkconfig oddjobd on;
	[[ $? -ne 0 ]] && Log_Msg Error "$0 failed to enable  oddjobd service" 5
fi
	
# Configure AD integration (Kerberos, Samba, SSSD)
cp -p /etc/krb5.conf /etc/krb5.conf_$(date '+%Y%m%d%H%M%S') 2>&1
cp -p /etc/samba/smb.conf /etc/samba/smb.conf_$(date '+%Y%m%d%H%M%S') 2>&1
 
cat > /etc/krb5.conf << EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log
 
[libdefaults]
 default_realm = NA.INTRANET.MSD
 dns_lookup_realm = true
 dns_lookup_kdc = true
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 
[realms]
 NA.INTRANET.MSD = {
  kdc = $Ad_Admin_Server
  admin_server = $Ad_Admin_Server
 }
 
[domain_realm]
 .na.intranet.msd = NA.INTRANET.MSD
 na.intranet.msd = NA.INTRANET.MSD
EOF

[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to update /etc/krb5.conf" 6

cat > /etc/samba/smb.conf << EOF
[global]
workgroup = NA
client signing = yes
client use spnego = yes
kerberos method = secrets and keytab
log file = /var/log/samba/%m.log
realm = NA.INTRANET.MSD
security = ads
EOF

[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to update /etc/samba/smb.conf" 7

cat > /etc/sssd/sssd.conf << EOF
[sssd]
config_file_version = 2
reconnection_retries = 3
sbus_timeout = 30
services = nss, pam
domains = na.intranet.msd
#debug_level=9
 
[nss]
filter_groups = root
filter_users = root
reconnection_retries = 3
override_shell = /bin/bash
#debug_level=9
 
[pam]
reconnection_retries = 3
#debug_level=9
 
[domain/na.intranet.msd]
id_provider = ad
ldap_id_mapping = True
ldap_idmap_range_size = 1000000
ad_server = $Ad_Server
ad_domain = na.intranet.msd
fallback_homedir = /home/%u
case_sensitive = False
#cache_credentials = True
enumerate = False
#debug_level=9
EOF

[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to update /etc/sssd/sssd.conf" 8
chmod 600 /etc/sssd/sssd.conf

# Join NA domain
echo $Ad_Password | net ads join createcomputer="$Ou_Path" -k -U $Ad_Account -S $Ad_Admin_Server

[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to join domain. net ads join command failed with error code $?" 9

# Start up SSSD
service sssd stop
rm -f /var/lib/sss/db/* /var/log/sssd/*
service sssd start

[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to start service sssd with error code $?" 10

# RHEL 7 specific
if [ x`cat /etc/os-release  | grep ^ID=` == xID=\"rhel\" ]; then 
	[[ $? -ne 0 ]] && systemctl enable sssd.service;
	Log_Msg Error "$0 Failed to enable sssd service with error code $?" 11
# AWS Linux specific
elif [ x`cat /etc/os-release  | grep ^ID=` == xID=\"amzn\" ]; then 
	chkconfig sssd on;
	[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to enable sssd service with error code $?" 11
fi

# Configure system to use SSSD for authentication (nsswitch, PAM)
cp -p /etc/nsswitch.conf /etc/nsswitch.conf_$(date '+%Y%m%d%H%M%S')
cp -p /etc/pam.d/system-auth-ac /etc/pam.d/system-auth-ac_$(date '+%Y%m%d%H%M%S')
cp -p /etc/pam.d/password-auth-ac /etc/pam.d/password-auth-ac_$(date '+%Y%m%d%H%M%S')
  
cat > /etc/pam.d/system-auth-ac << EOF
#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authconfig is run.
auth       required      pam_env.so
# auth        sufficient    pam_fprintd.so
auth       sufficient    pam_unix.so nullok try_first_pass
auth       requisite     pam_succeed_if.so uid >= 500 quiet
auth       sufficient    pam_sss.so use_first_pass
auth       required      pam_deny.so
 
account    required      pam_unix.so broken_shadow
account    sufficient    pam_localuser.so
account    sufficient    pam_succeed_if.so uid < 500 quiet
account    [default=bad success=ok user_unknown=ignore] pam_sss.so
account    required      pam_permit.so
 
password   requisite     pam_cracklib.so try_first_pass retry=3 type=
password   sufficient    pam_unix.so shadow nullok try_first_pass use_authtok
password   sufficient    pam_sss.so use_authtok
password   required      pam_deny.so
 
session    optional      pam_keyinit.so revoke
session    required      pam_limits.so
session optional      pam_oddjob_mkhomedir.so skel=/etc/skel umask=0077
session    [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session    required      pam_unix.so
session    optional      pam_sss.so
EOF

[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to update /etc/pam.d/system-auth-ac" 12

cat > /etc/pam.d/password-auth-ac << EOF
#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the nexttime authconfig is run.
auth       required      pam_env.so
auth       sufficient    pam_unix.so nullok try_first_pass
auth       requisite     pam_succeed_if.so uid >= 500 quiet
auth       sufficient    pam_sss.so use_first_pass
auth       required      pam_deny.so
 
account    required      pam_unix.so broken_shadow
account    sufficient    pam_localuser.so
account    sufficient    pam_succeed_if.so uid < 500 quiet
account    [default=bad success=ok user_unknown=ignore] pam_sss.so
account    required      pam_permit.so
 
password   requisite     pam_cracklib.so try_first_pass retry=3 type=
password   sufficient    pam_unix.so shadow nullok try_first_pass use_authtok
password   sufficient    pam_sss.so use_authtok password   required      pam_deny.so
 
session    optional      pam_keyinit.so revoke
session    required      pam_limits.so
session    optional     pam_oddjob_mkhomedir.so skel=/etc/skel umask=0077
session    [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session    required      pam_unix.so
session    optional      pam_sss.so
EOF

[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to update /etc/pam.d/password-auth-ac" 13

# Configure SSH to use SSSD for access control
cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
sed -i 's/^GSSAPIAuthentication no\|^#GSSAPIAuthentication yes/GSSAPIAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^GSSAPICleanupCredentials no\|^#GSSAPICleanupCredentials yes/GSSAPICleanupCredentials yes/g' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
##sed -i 's/^PermitRootLogin no\|^PermitRootLogin yes/PermitRootLogin forced-commands-only/g' /etc/ssh/sshd_config
 
# Configure ssh to use AD groups for access control - NOTE: group names must be lower-case to match!!
cat >>  /etc/ssh/sshd_config << EOF

# Allow members of management remote access group to SSH to instance (and ec2-user group as backup)
AllowGroups ec2-user $Remote_Access_Group
EOF

[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to update /etc/ssh/sshd_config" 14
# Configure sudo to use AD groups for priv escalation - NOTE: group names must be lower-case to match!!
cat > /etc/sudoers.d/mgmt-privilege << EOF
# Allow members of management privilege group to run all commands
%$Remote_Priviliaged_Group ALL=(ALL) ALL
EOF
[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to update /etc/sudoers.d/mgmt-privilege" 15

service sshd reload
[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed to reload service sshd with error code $?" 16
exit 0

