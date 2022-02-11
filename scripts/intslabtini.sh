#!/bin/bash
## SCRIPT FOR IAC LINUX SYSTEMS
# INTERFACE TO RUN INTSLABTINI.F90
. /etc/profile.d/modules.sh

# ---------------------------------------------------------------------
# Usage, parameter settings
# ---------------------------------------------------------------------

# Set LAGRANTO environment variable
LAGRANTO="/home/atroman/tools/lagranto.hy"

# Write usage information
if [ $# -eq 0 ] || [ $# -lt 3 ]; then
  echo "USAGE: intslabtini.sh infile outfile integrationtime"
  echo
  exit
fi

# Write title
echo
echo '========================================================='
echo '       *** START OF PREPROCESSOR INTSLABTINI ***           '
echo

# Get the arguments
inpfile=$1
outfile=$2
inttime=$3

# Set base directories (run+prog)
cdfdir=${PWD}
tradir=${PWD}

# Set program paths and filenames
parname=intslabtini.param
parfile=${tradir}/${parname}
prog=${LAGRANTO}/intslabtini/intslabtini

# Set the prefix of the primary and secondary data files
charp='P'
chars='S'

echo '---- DIRECTORIES AND PROGRAMS ---------------------------'
echo
echo "CDF dir               : ${cdfdir}"
echo "PROGRAM dir           : ${tradir}"
echo "PROGRAM               : ${prog}"
echo "PARAMETER file        : ${parfile}"
echo

# ---------------------------------------------------------------------
# Set optional flags
# ---------------------------------------------------------------------

# Set some default values
# set 1 for sigma and 2 for a pressure grid
hmode='1'
# Grid information

#xmin=0.0 # if date-line should be zero degrees meridian
# xmin='-30.0'
# ymin='45.0'

# 0.1 degrees
# dx='0.1'
# dy='0.1'
# nx='151'
# ny='71'
# xmin='-30.0'
# ymin='45.0'
# 0.4 degrees
# dx='0.4'
# dy='0.4'
# nx='41'
# ny='21'
# xmin='-30.0'
# ymin='44.0'
# 0.25 degrees
# dx='0.25'
# dy='0.25'
# nx='93'
# ny='45'
# xmin='-28.0'
# ymin='44.0'
# nz='40'
# 0.2 degrees
dx='0.2'
dy='0.2'
nx='301'
ny='201'
xmin='-45.0'
ymin='30.0'
nz='40'

# Special case, remove after usage!!
# dx='0.4'
# dy='0.4'
# xmin='-180.0'
# ymin='0.0'
# nx='900'
# ny='226'
# nz=14

# ---------------------------------------------------------------------
# Handle the input trajectory file
# ---------------------------------------------------------------------

# Check whether the input file can be found
if [ ! -f ${inpfile} ]; then
    echo " ERROR : Input file ${inpfile} is missing"
    exit
fi

# Get the start, end and reference date for the tracing

# Why is this if done the way it is: https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash
if [[ "$inpfile" == "${inpfile%.3}" ]]; then

    # IMPROVED AND FASTER WAY TO GET NEEDED INFO IN ASCII FORM
    inpmode=1
    line=$(head -n 1 ${inpfile})
    linearray=($line)
    startdate=${linearray[2]}
    refdate=$(gettidiff $startdate 19500101_00)

    # Read number of tra etc from file header
    if [ ${#linearray[@]} -gt 8  ]; then

    ntra=${linearray[9]}
    ntim=${linearray[11]}
    ncol=${linearray[13]}

    else # Slow method to get number of trajectories

    emptylines=$(grep -cvP '\S' ${inpfile}) # Number of empty lines
    ntra=$((emptylines-1))                  # Number of trajectories
    hours=$((${linearray[6]}/60))
    ntim=$((${hours#-}+1))
    ncol=$(awk '{print NF}' ${inpfile} | sort -nu | tail -n 1)

    fi

else

    inpmode=3
   # startdate=${parsu}
   # refdate=$(gettidiff $startdate 19500101_00)
    ntra=$(${LAGRANTO}/goodies/trainfo.sh ${inpfile} ntra)
    ntim=$(${LAGRANTO}/goodies/trainfo.sh ${inpfile} ntim)
    ncol=$(${LAGRANTO}/goodies/trainfo.sh ${inpfile} ncol)

fi

# Check format of startdate
# ns=$(echo $startdate | sed -e 's/_[0-9]*//' | wc -c)

# if [ ! "$ns" -eq 9 ]; then
  # echo " ERROR: Date format must be yyyymmdd ***"
  # exit
# fi

# ---------------------------------------------------------------------
# Prepare input file for integrate and run it
# ---------------------------------------------------------------------

# echo "DEBUG:"
# echo $inpfile
# echo $outfile
# echo $ntra
# echo $ntim
# echo $ncol
# echo $nx
# echo $ny
# echo $nz
# echo $dx
# echo $dy
# echo $xmin
# echo $ymin
# echo $hmode
# echo $inpmode

# Write parameter file
rm -f ${parfile}
touch ${parfile}

echo $inpfile                                              >> $parfile
echo $outfile                                              >> $parfile
echo $ntra                                                 >> $parfile
echo $ntim                                                 >> $parfile
echo $ncol                                                 >> $parfile
echo $nx                                                   >> $parfile
echo $ny                                                   >> $parfile
echo $nz                                                   >> $parfile
echo $dx                                                   >> $parfile
echo $dy                                                   >> $parfile
echo $xmin                                                 >> $parfile
echo $ymin                                                 >> $parfile
echo $hmode                                                >> $parfile
echo $inpmode                                              >> $parfile
echo $inttime											   >> $parfile

# Finish the preprocessor
echo
echo '       *** END OF PREPROCESSOR INTSLABTINI ***             '
echo '========================================================='
echo

# Run program (the "echo $parname |" passes the name of the parameter file to the fortran program)
echo $parname | ${prog}
