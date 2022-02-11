#!/bin/bash
# SCRIPT FOR IAC LINUX SYSTEMS
# Computes secondary fields from P-Files, tropopause LABELING and
# compresses final files
#
# roman.attinger@env.ethz.ch

## SCRIPT FOR IAC LINUX SYSTEMS
# Converts GRIB → NetCDF
. /etc/profile.d/modules.sh

# load dyn_tools & NCL

module 'load ncl/6.2.1'
module 'load dyn_tools'
module 'load cdo/1.7.0'

export OMP_NUM_THREADS=8

cd /net/thermo/atmosdyn2/atroman/stingjet/fc/cdf/

#echo "sleeping for 1 day"
#sleep 1d

files=P*
filearray=($files)      # all files as array
nfiles=${#filearray[@]} # number of elements in array
echo "read: ${filearray[@]} "

i=0
while [ $i -lt $nfiles ]
do
  echo "found $nfiles"

  while [ ! -f S${filearray[i]#P} ]; do
    echo '********************************************************'
    echo "Computing PV rates on ${filearray[i]} to S${filearray[i]#P}"
    date
    echo '********************************************************'

    # Generate secondary fields
    #~/tools/p2s/p2s_ddh2 ${filearray[i]} P TH THE THW RH PV VORT PVRCONVT PVRCONVM PVRTURBT PVRTURBM PVRLS PVRSW PVRLWH PVRLWC PVRCOND PVREVC PVREVR PVRDEP PVRSUBI PVRSUBS PVRMELTI PVRMELTS PVRFRZ PVRRIME PVRBF -v
	
	~/tools/p2s/p2s_ddh2 ${filearray[i]} P TH THE THW RH PV -v

    # Compute tropopause
    #~/tools/tropopause/tropopause.sh ${filearray[i]#P}
  
    # correct attributes and compress...
	#~/phd/fixcomp/fixcomp.sh S${filearray[i]#P} -o

    # Remove LABEL on L file, rename L file and remove L_cst
    #ncks -O -x -v LABEL L${filearray[i]#P} TP${filearray[i]#P}
    #rm L${filearray[i]#P}*

  done # does S file exist?
  
  i=$[$i+1]
  # look for new files
  files=P*
  filearray=($files)      # all files as array
  nfiles=${#filearray[@]} # number of elements in array

done # run through all files
