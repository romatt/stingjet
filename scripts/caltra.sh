#!/bin/bash
## SCRIPT FOR IAC LINUX SYSTEMS
# Computes backward trajectories on IFS model data in parallel
# Each worker needs to have its own folder to do the trajectory
# computation to avoid conflicts with caltra.param file
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
backtime=12

for i in $(seq 0 10); do
	t1=$((st+i))
	t2=$((t1-backtime))
	t1=$(newtime 19500101_00 $t1)
	t2=$(newtime 19500101_00 $t2)
	~/tools/lagranto.ifs/caltra/caltra.sh $t1 $t2 ${t1}_start tra_${t1}.3
done
