#!/bin/bash
#
# Prints out how many seconds ago this EC2 instance was started
#
# It uses Last-Modified header returned by EC2 metadata web service, which as far
# as I know is not documented, and hence I assume there is no guarantee
# that Last-Modified will be always set correctly.
#
# Use at your own risk.
#

t=/tmp/ec2.running.seconds.$$

if wget -q -O $t http://169.254.169.254/latest/meta-data/local-ipv4 ; then
	#echo $(( `date +%s` - `date -r $t +%s` ))
        y=$(echo $(( `date +%s` - `date -r $t +%s` )))
        x=$(echo $(( $y/3600 )))
        echo "ec2 instance running for $x hours" 
	rm -f $t
	exit 0
fi

exit 1
