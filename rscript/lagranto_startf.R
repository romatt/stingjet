# R script producing start file for LAGRANTO (lon, lat, p) of sting jet tini case
#
# roman.attinger@env.ethz.ch

# Load libraries
library(ncdf4)
library(mgcv)
library(lattice)

# Settings
root_path="/net/thermo/atmosdyn2/atroman/stingjet/20140211_12/"
t1="20140212_00"
t2="20140212_10"
specific_cy=-999
lonmin=-60
lonmax=15
dellon=0.25
latmin=20
latmax=80
dellat=0.25

# FUNCTION TO CHECK IF VALUE IS ROUGHLY EQUAL
requal<-function(a,b) {
  if((b+0.1)>a && (b-0.1)<a) {
    returnValue(TRUE)
  } else {
    returnValue(FALSE)
  }
}

# FILE PATHS
in_path=paste(root_path,"/cdf",sep="")
out_path=paste(root_path,"/tra",sep="")

# Model grid specifications
longitudes=seq(lonmin,lonmax,dellon)
latitudes=seq(latmin,latmax,dellat)
levels=seq(1,40)
nlon=length(longitudes)
nlat=length(latitudes)
nlev=length(levels)

sellon1=-28
sellon2=-5
sellat1=44
sellat2=55

sellongitudes=seq(which(longitudes==sellon1),which(longitudes==sellon2))
sellatitudes=seq(which(latitudes==sellat1),which(latitudes==sellat2))
nsellon=length(sellongitudes)
nsellat=length(sellatitudes)

aklay.IFS=c(0.0, 0.01878906, 0.1329688, 0.4280859, 0.924414, 1.62293, 2.524805,
            3.634453, 4.962383, 6.515273, 8.3075, 10.34879, 12.65398, 15.23512,
            18.10488, 21.27871, 24.76691, 28.58203, 32.7325, 37.22598, 42.06668,
            47.25586, 52.7909, 58.66457, 64.86476, 71.37383, 78.16859, 85.21914,
            92.48984, 99.93845, 107.5174, 115.1732, 122.848, 130.4801, 138.0055,
            145.3589, 152.4757, 159.2937, 165.7537, 171.8026, 177.3938, 182.4832,
            187.0358, 191.0384, 194.494, 197.413, 199.8055, 201.683, 203.0566,
            203.9377, 204.339, 204.2719, 203.7509, 202.7876, 201.398, 199.5966,
            197.3972, 194.8178, 191.874, 188.585, 184.9708, 181.0503, 176.8462,
            172.382, 167.6806, 162.7672, 157.6719, 152.4194, 147.0388, 141.5674,
            136.03, 130.4577, 124.8921, 119.3581, 113.8836, 108.5065, 103.2531,
            98.1433, 93.19541, 88.42462, 83.83939, 79.43382, 75.1964)

bklay.IFS=c(0.9988151, 0.9963163, 0.9934933, 0.9902418, 0.9865207, 0.9823067,
            0.977575, 0.9722959, 0.9664326, 0.9599506, 0.9528069, 0.944962,
            0.9363701, 0.9269882, 0.9167719, 0.9056743, 0.893654, 0.8806684,
            0.8666805, 0.8516564, 0.8355686, 0.8183961, 0.8001264, 0.7807572,
            0.7602971, 0.7387676, 0.7162039, 0.692656, 0.6681895, 0.6428859,
            0.6168419, 0.5901701, 0.5629966, 0.5354602, 0.5077097, 0.4799018,
            0.4521973, 0.424758, 0.3977441, 0.3713087, 0.3455966, 0.3207688,
            0.2969762, 0.274298, 0.2527429, 0.2322884, 0.212912, 0.1945903,
            0.1772999, 0.1610177, 0.145719, 0.1313805, 0.1179764, 0.1054832,
            0.0938737, 0.08312202, 0.07320328, 0.06408833, 0.05575071, 0.04816049,
            0.04128718, 0.03510125, 0.02956981, 0.02465918, 0.02033665, 0.01656704,
            0.01331083, 0.01053374, 0.008197418, 0.006255596, 0.004674384,
            0.003414039, 0.002424481, 0.001672322, 0.001121252, 0.0007256266,
            0.0004509675, 0.0002694785, 0.0001552459, 8.541815e-05, 4.1635e-05,
            1.555435e-05, 3.39945e-06)

# Time range
t1 <- as.POSIXct(t1,format="%Y%m%d_%H")
t2 <- as.POSIXct(t2,format="%Y%m%d_%H")
#dates <- c(t1,t2)
dates <- seq(t1, t2, by=paste(1," hours",sep=""))

for (ind in 1:length(dates)){
  day=dates[ind]
  tstep=format(day,"%Y%m%d_%H")
  cat(tstep,"\n")

  # Read NetCDF files
  pncfname <- paste(in_path,"/P",tstep,sep="") # P-Files

  ncin <- nc_open(pncfname)
  PS <- ncvar_get(ncin,"PS")
  nc_close(ncin)

  # Array holding starting positions
  t<-array(0,dim=c(0,3))

  cat("Working on",tstep,"\n")

  for(z in levels) {

    cat("l",z,"\n")

    levs<-aklay.IFS[rep(z,nsellon*nsellat)]+bklay.IFS[rep(z,nsellon*nsellat)]*PS[matrix(c(rep(sellongitudes,each=nsellat),rep(sellatitudes,nsellon)),ncol=2,nrow=(nsellon*nsellat))]
    t <- rbind(t,data.frame(lon=round(longitudes[rep(sellongitudes,each=nsellat)],digits=2),lat=round(latitudes[rep(sellatitudes,nsellon)],digits=2),height=levs))

  } # Levels

  # Write this segment to disk
  write.table(t, file=paste(out_path,"/",tstep,"_start",sep=""),col.names=FALSE,row.names=FALSE,quote=FALSE)

} # Iterate through dates


# Find which trajectory a specific lon / lat combination has
searchlon=-30
searchlat=44

for(row in 1:length(t[,1])) {
  if(requal(searchlon,t[row,1]) & requal(searchlat,t[row,2])) {
    cat(row,"lon",t[row,1],"lat",t[row,2],"p",t[row,3],"\n")
  }
}
