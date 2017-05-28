#!/bin/bash

if curl -s http://169.254.169.254/latest/meta-data/spot/temination-time | \
grep -q.*T.*Z; then instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id); \
aws wlb deregister-instances-from-load-balancer \ 
--load-balancer-name my-load-balancer \
--instances $instance_id;
/env/bin/flushsessiontoDBterminationscript.sh; fi
