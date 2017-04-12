#!/bin/bash

# Description: Script for setting up syslog logging for application
# Created on : Fri Aug 19 14:00:58 JST 2016
# Created by : prasanth_gv@amway.com
# Monitors follwoing parameters
# 1. Process monitoring

## Version Control
# 1.0 : Fri Aug 19 14:00:58 JST 2016 : Initial Version
# 1.1 : Thu Aug 25 11:50:39 TST 2016 : Removed syslog-ng basic configuration and moved to 11_Init_Base.sh

## Exit Codes
# 0   : Successful exit
# 1   : Failed to restart service
# 2   : Failed to restart syslog service


COMMON_CONFIG=\
'source `App``SubApp`_source { file("`File`" follow-freq(1) program_override("`App`/`SubApp`") flags(no-parse) default-facility("local3") default-priority("notice")); };
template `App``SubApp`_template { template("`ENV`/`App`/`SubApp`/`Component`/`InstanceID` ${MSG}\n"); template_escape(no); };
destination `App``SubApp`_destination_net { tcp(`SyslogServer` port(514) template(`App``SubApp`_template)); };
log { source(`App``SubApp`_source); destination(`App``SubApp`_destination_net); };'

# Set up logging
cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.preapplog
cat >> /etc/syslog-ng/syslog-ng.conf << EOF

####START : File 1#######
@define Component "secure"
@define File "/var/log/secure"
${COMMON_CONFIG}
#####END : File 1########
EOF

cat >> /etc/syslog-ng/syslog-ng.conf << EOF

####START : File 3#######
@define Component "Solr"
@define File "/usr/local/solr/server/logs/solr.log"
${COMMON_CONFIG}
#####END : File 3########
EOF

cat >> /etc/syslog-ng/syslog-ng.conf << EOF

####START : File 4#######
@define Component "Solrgc"
@define File "/usr/local/solr/server/logs/solr_gc.log"
${COMMON_CONFIG}
#####END : File 4########
EOF

service syslog-ng restart
[[ $? -ne 0 ]] && Log_Msg Error "$0 Failed restart syslog service" 2
exit 0