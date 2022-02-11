#!/bin/bash
# PROJECT: STINGJET
#
# Script to update tracevars file, then tracing of variables along backward
# trajectories and finally integrating theta and pv tendencies along those
# trajectories. We Can specify how long the integration period should be using
# the final argument passed to intslabtini.sh
#
# WARNING: MAKE SURE TO UPDATE tracefast.sh WITH THE PROPER DOMAIN DIMENSIONS!!!
# 
# Updated on 11.02.2022

. /etc/profile.d/modules.sh

# load dyn_tools
module 'load dyn_tools'

# this is where the start files are
basedir="/net/thermo/atmosdyn2/atroman/stingjet/fc/tra"
cd $basedir

startdate="20140212_00"
st=$(gettidiff $startdate 19500101_00)

for i in $(seq 0 10); do

	# Define times
	t1=$((st+i))
	t1=$(newtime 19500101_00 $t1)
	
	##### U,V,OMEGA #####

	ln -sf /home/atroman/projects/stingjet/scripts/tracevars tracevars
	trace tra_${t1}.3 traced_${t1}.3
	
	# ##### TH #####

	ln -sf /home/atroman/projects/stingjet/scripts/tracevars_TH tracevars
	trace tra_${t1}.3 tracedth_${t1}.3
	~/tools/lagranto.hy/intslabtini/intslabtini.sh tracedth_${t1}.3 ATH12_${t1}.nc 12
	~/tools/lagranto.hy/intslabtini/intslabtini.sh tracedth_${t1}.3 ATH6_${t1}.nc 6
	
	##### PV #####

	ln -sf /home/atroman/projects/stingjet/scripts/tracevars_PV tracevars
	trace tra_${t1}.3 tracedpv_${t1}.3
	reformat tracedpv_${t1}.3 tracedpv_${t1}.1
	~/tools/lagranto.hy/intslabtini/intslabtini.sh tracedpv_${t1}.3 APV12_${t1}.nc 12	
	~/tools/lagranto.hy/intslabtini/intslabtini.sh tracedpv_${t1}.3 APV6_${t1}.nc 6
	
done