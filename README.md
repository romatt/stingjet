# StingJet Analysis Cyclone Tini
Repository to analyze the sting jet in cyclone Tini.

## Workflow

This section describes the workflow necessary to compute integrated PV tendencies along 12-h backward trajectories.

The following are required dependencies:
- p2s/p2s_ddh2
- [Official LAGRANTO](https://git.iac.ethz.ch/atmosdyn/Lagranto)
- LAGRANTO.IFS (caltra and intslabtini)

1. Calculate secondary files using `scripts/p2s.sh` and modify the following lines if necessary

```bash
# Number of threads to use
export OMP_NUM_THREADS=8
# Change the file location
cd /net/thermo/atmosdyn2/atroman/stingjet/fc/cdf/
# Define which variables should be computed
~/tools/p2s/p2s_ddh2 ${filearray[i]} P TH THE THW RH PV -v
```

2. Generate trajectory starting points using `rscript/lagranto_startf.R` after updating the settings section

```R
# Data directory
root_path="/net/thermo/atmosdyn2/atroman/stingjet/fc/"
# First date to run trajectories from
t1="20140212_00"
# Last date to run trajectories from
t2="20140212_10"
lonmin=-45
lonmax=15
dellon=0.2
latmin=30
latmax=70
dellat=0.2
```

3. Calculate trajectories using `scripts/caltra.sh`

> Note: Instead of the official LAGRANTO caltra, this workflow makes use of a modified version of caltra which allows starting points to be on model levels. This enables the reverse-filling technique of integrating variables along trajectories at discrete model grid-points. 

```bash
# Modify processing directory if necessary
basedir="/net/thermo/atmosdyn2/atroman/stingjet/fc/tra"
# Starting day from which trajectories are run
startdate="20140212_00"
# Number of hours to run backward trajectories
backtime=12
```

4. Trace variables along trajectories and integrate the traced variables using `scripts/trace_int.sh`

Before running the tracing and integration script, make sure to update the domain and grid specifications in `scripts/intslabtini.sh`

```bash
# Delta longitudes
dx='0.2'
# Delta latitudes
dy='0.2'
# Number of longitude grid points 
nx='301'
# Number of latitude grid points
ny='201'
# Minimum longitude
xmin='-45.0'
# Maximum latitude
ymin='30.0'
# Number of levels
nz='40'
```