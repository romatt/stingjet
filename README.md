# StingJet Analysis Cyclone Tini
Repository to analyze the sting jet in cyclone Tini.

## Workflow

This section describes the workflow necessary to compute integrated PV tendencies along 12-h backward trajectories.

1. Calculate secondary files using `scripts/p2s.sh` and modify the following lines if necessary

    # Number of threads to use
	export OMP_NUM_THREADS=8
	# Change the file location
	cd /net/thermo/atmosdyn2/atroman/stingjet/fc/cdf/
	# Define which variables should be computed
	~/tools/p2s/p2s_ddh2 ${filearray[i]} P TH THE THW RH PV -v


	

