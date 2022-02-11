# plot_traj.R
#
# Script to plot evolution of PV and individual PV tendencies along
# trajectories originating in region of high wind of cyclone Tini
# 
# Roman Attinger

Sys.setenv(TZ='GMT')

# Load libraries
library(data.table)
library(ggplot2)
library(ggpubr)
library(matrixStats) # this is pretty neato :)
require(scales) # for date format
#library(metplot)
#library(zeallot) # Simple variable unpacking
library(tmaptools)

# Which resolution?
reso="025"

# Want additional PV tendency info?
indv=T

# Traced variables
tracedPV=c("time","lon","lat","p","PS","PV","PVRLS","PVRCOND","PVRDEP","PVREVC","PVREVR","PVRSUBS","PVRMELTS","PVRFRZ","PVRRIME","PVRCONVT","PVRCONVM","PVRTURBT","PVRTURBM","PVRSW","PVRLWH","PVRLWC")
tracedM=c("time","lon","lat","p","PS","U","V","Q","LWC","RWC","SWC","IWC","THW","THE","VORT")
tracedTH=c("time","lon","lat","p","PS","TH","tls","tcond","tdep","tevc","tevr","tsubs","tmelts","tfrz","trime","tconv","tmix","tsw","tlw")

# Manually define cyclone position during times of interest
CYCLONE<-data.frame(date=c("20140211_14","20140211_15","20140211_16","20140211_17","20140211_18","20140211_19","20140211_20","20140211_21","20140211_22","20140211_23","20140212_00","20140212_01","20140212_02","20140212_03","20140212_04","20140212_05","20140212_06","20140212_07","20140212_08","20140212_09","20140212_10","20140212_11","20140212_12"),
                  lon=c(-34.75,-33.5,-32.5,-31,-30,-28.75,-27.75,-26.5,-25.5,-24.25,-23.25,-21.75,-20.25,-18.75,-17.25,-16,-14.75,-13.75,-12.75,-12.25,-11,-10.5,10),
                  lat=c(46.75,47.25,47.5,48,48.25,48.5,49,49.5,49.5,50,50,50,50.25,50.25,50.75,51,51.5,52,52.5,52.75,53,53.25,53.5))
CYCLONE<-CYCLONE[nrow(CYCLONE):1,] # Reverse cyclone position to fit backward trajectories

# This is the area of interest for the 10 time steps
extract<-data.frame(minlon=c(-26,-25.25,-23.25,-22.25,-20.75,-20,-19.5,-18.25,-17.25,-17.25,-14.75),
                    maxlon=c(-18.5,-17.5,-16.75,-15.5,-14,-12.5,-12,-10,-9,-7,-7),
                    minlat=c(45,46,46.25,45.75,46,46,47,46,46.75,46.25,48.5),
                    maxlat=c(50.25,50.25,50.5,50.5,51,51,51.5,51.5,52,52.5,52))
dh=4
pd=100

# inpv=paste("/net/thermo/atmosdyn2/atroman/stingjet/tra_",reso,"/tracedpv_",sdate,".1",sep="")
# inth=paste("/net/thermo/atmosdyn2/atroman/stingjet/tra_",reso,"/tracedth_",sdate,".1",sep="")
# inm=paste("/net/thermo/atmosdyn2/atroman/stingjet/tra_",reso,"/traced_",sdate,".1",sep="")

# start <- as.POSIXct("20140212_01",format="%Y%m%d_%H")
# end <- as.POSIXct("20140211_13",format="%Y%m%d_%H")

# Define backward trajectory starting dates
trajdate_start<-"20140212_00"
trajdate_end<-"20140212_10"
trajdates<-seq(as.POSIXct(trajdate_start,format="%Y%m%d_%H"),as.POSIXct(trajdate_end,format="%Y%m%d_%H"),by=paste(1," hours",sep=""))

cmap<-c("PV"="#0017ED",
        "PVRTOT"="black",
        "PVRRES"="#607D8B",
        "PVRCONVT"="#F28E2B",
        "PVRCONVM"="#F28E2B",
        "PVRTURBT"="#59A14E",
        "PVRTURBM"="#59A14E",
        "PVRLWH"="#EDC949",
        "PVRLWC"="#EDC949",
        "PVRCOND"="#E15759",
        "PVREVC"="#393D3F",
        "PVREVR"="#2176AE",
        "PVRMELTS"="#00A6ED",
        "PVRSUBS"="#390099",
        "PVDIFF"="white",
        "PVRLS"="#EE2C2C",
        "PVRSW"="#EDC949",
        "PVRDEP"="#6b430c",
        "PVRMELTI"="white",
        "PVRSUBI"="blueviolet",
        "PVRFRZ"="purple",
        "PVRRIME"="green",
        "OTHERS"="#D8CBC7",
        "MAP"="gray",
        "BORDER"="black")

# Iterate over all starting dates
for(t in 1:length(trajdates)) {
#for(t in 4:6) {
  
  trajdate=trajdates[t]
  # Dates covered by backward trajectory
  sdate <- format(trajdate,"%Y%m%d_%H")
  start <- trajdate
  end <- trajdate-12*60*60 # Trajectories are 12 hours long
  dates <- seq(start, end, by=paste(-1," hours",sep=""))
  ntim=length(dates)
  
  # Find correspondig cyclone positions
  cysel=which(CYCLONE$date==sdate)
  cypos=CYCLONE[cysel:(cysel+9),]
  
  # Read trajectory information
  inpv=paste("/net/thermo/atmosdyn2/atroman/stingjet/20140211_12/tra/tracedpv_",sdate,".1",sep="")
  inth=paste("/net/thermo/atmosdyn2/atroman/stingjet/20140211_12/tra/tracedth_",sdate,".1",sep="")
  inm=paste("/net/thermo/atmosdyn2/atroman/stingjet/20140211_12/tra/traced_",sdate,".1",sep="")
  
  cat(paste("Reading ",inpv,"\n",sep=""))
  dataPV<-fread(inpv, sep="auto", header = FALSE, skip=5, col.names=tracedPV,blank.lines.skip=T,na.strings="-999.99")
  
  cat(paste("Reading ",inm,"\n",sep=""))
  dataM<-fread(inm, sep="auto", header = FALSE, skip=5, col.names=tracedM,blank.lines.skip=T,na.strings="-999.99")
  
  cat(paste("Reading ",inth,"\n",sep=""))
  dataTH<-fread(inth, sep="auto", header = FALSE, skip=5, col.names=tracedTH,blank.lines.skip=T,na.strings="-999.99")
  
  # Read variables
  #c(TH_DIFF,lons_thdiff,lats_thdiff)%<-%rfile(paste("/net/thermo/atmosdyn2/atroman/stingjet/20140211_12/tra/ATH12_",sdate,".nc",sep=""),"TH_DIFF","lon","lat")
  #c(U,V,lons,lats)%<-%rfile(paste("/net/thermo/atmosdyn2/atroman/stingjet/20140211_12/cdf/P",sdate,sep=""),"U","V","lon","lat")
  
  # Generate raster
  #THr <- mkrast(TH_DIFF,lons=lons,lats=lats)
  
  cat("Successfully read data\n")
  
  # This is the sequence containing the starting position of each trajectory
  exseq<-seq(1,length(dataPV$time),ntim)
  
  # Search for trajectories with wind exceeding 50m/s, within certain geographical region
  extract_wind<-sqrt(dataM$U[exseq]^2+dataM$V[exseq]^2)
  extract_lon<-dataM$lon[exseq]
  extract_lat<-dataM$lat[exseq]
  extract_p<-dataM$p[exseq]
  extract_p_3<-dataM$p[exseq+dh] # CHANGE THIS IF REQUIRED!!!
  # Remove NA values from p
  extract_p_3[extract_p_3<(-999)]<-NA
  pdiff<-extract_p-extract_p_3
  
  # Only select trajectories of interest
  # 20140212_02
  #sel<-which(extract_wind>=50 & extract_lon<(-20) & extract_lon>(-22.5) & extract_lat>48.5 & extract_lat<50.5 & extract_p>710 & pdiff>100) # OLD
  #sel<-which(extract_wind>=50 & extract_lon<(-20) & extract_lon>(-22.5) & extract_lat>48.5 & extract_lat<50.5 & extract_p>710)
  
  # 20140212_01
  #sel<-which(extract_wind>=50 & extract_lon<(-20) & extract_lon>(-24) & extract_lat>48.5 & extract_lat<50 & extract_p>710 & pdiff>100 & pdiff<1000)
  #sel<-which(extract_wind>=50 & extract_lon<(-20) & extract_lon>(-24) & extract_lat>48.5 & extract_lat<50 & extract_p>800)
  
  # 20140212_07
  #sel<-which(extract_wind>=47 & extract_lon<(-12) & extract_lon>(-16) & extract_lat>49 & extract_lat<51 & extract_p>780)
  
  # Select region
  
  sel<-which(extract_lon>(extract$minlon[t]) & extract_lon<(extract$maxlon[t]) &
               extract_lat>extract$minlat[t] & extract_lat<extract$maxlat[t] & extract_p>780 & pdiff>=pd)
  
  # Select the 50 strongest wind
  wind_sorted<-sort(extract_wind[sel],decreasing = T, index.return=T)
  
  # Select a specific threshold for high wind events
  nvals=length(which(wind_sorted$x>47))
  
  if(nvals==0) next
  
  selnew<-sel[wind_sorted$ix[1:nvals]] 
  
  #if(length(sel)>50) {

#  } else {
#    selnew<-sel
#  }

  # Extract trajectories of interest
  PVlist<-lapply(selnew, function(s) dataPV[(exseq[s]:(exseq[s]+(ntim-1))),])
  Mlist<-lapply(selnew, function(s) dataM[(exseq[s]:(exseq[s]+(ntim-1))),])
  THlist<-lapply(selnew, function(s) dataTH[(exseq[s]:(exseq[s]+(ntim-1))),])
  
  # Extract values
  LON<-sapply(PVlist,function(x) unlist(x[,"lon"]))
  LAT<-sapply(PVlist,function(x) unlist(x[,"lat"]))
  P<-sapply(PVlist,function(x) unlist(x[,"p"]))
  PV<-sapply(PVlist,function(x) unlist(x[,"PV"]))
  
  if(indv) {
    PVRLS<-sapply(PVlist,function(x) unlist(x[,"PVRLS"]))
    PVRCOND<-sapply(PVlist,function(x) unlist(x[,"PVRCOND"]))
    PVRDEP<-sapply(PVlist,function(x) unlist(x[,"PVRDEP"]))
    PVREVC<-sapply(PVlist,function(x) unlist(x[,"PVREVC"]))
    PVREVR<-sapply(PVlist,function(x) unlist(x[,"PVREVR"]))
    PVRSUBS<-sapply(PVlist,function(x) unlist(x[,"PVRSUBS"]))
    PVRMELTS<-sapply(PVlist,function(x) unlist(x[,"PVRMELTS"]))
    PVRFRZ<-sapply(PVlist,function(x) unlist(x[,"PVRFRZ"]))
    PVRRIME<-sapply(PVlist,function(x) unlist(x[,"PVRRIME"]))
    PVRCONVT<-sapply(PVlist,function(x) unlist(x[,"PVRCONVT"]))
    PVRCONVM<-sapply(PVlist,function(x) unlist(x[,"PVRCONVM"]))
    PVRTURBT<-sapply(PVlist,function(x) unlist(x[,"PVRTURBT"]))
    PVRTURBM<-sapply(PVlist,function(x) unlist(x[,"PVRTURBM"]))
    PVRLWH<-sapply(PVlist,function(x) unlist(x[,"PVRLWH"]))
    PVRLWC<-sapply(PVlist,function(x) unlist(x[,"PVRLWC"]))
    PVRSW<-sapply(PVlist,function(x) unlist(x[,"PVRSW"]))
    PVRTOT<-PVRLS+PVRCONVT+PVRCONVM+PVRTURBT+PVRTURBM+PVRLWH+PVRLWC+PVRSW
    
    # Replace the last value in the PVRTOT with the absolute PV
    PVRTOT[10,]<-PV[10,]
   # PVRTOT[9,]<-PV[9,]
   # PVRTOT[8,]<-PV[8,]
    
    # Add previous entry to current value
    for(i in 9:1) {
      PVRTOT[i,]=PVRTOT[(i+1),]+PVRTOT[i,]
    }
  }
  
  p<-sapply(PVlist,function(x) unlist(x[,"p"]))
  U<-sapply(Mlist,function(x) unlist(x[,"U"]))
  V<-sapply(Mlist,function(x) unlist(x[,"V"]))
  WND=sqrt(U^2+V^2)
  TH<-sapply(THlist,function(x) unlist(x[,"TH"]))
  
  # Define NA values
  PV[PV<(-900)] <- NA 
  PVRLS[PVRLS<(-900)] <- NA 
  p[p<(-900)] <- NA 
  TH[TH<(-900)] <- NA
  
  if(indv) {
    # PV with diagnosed PVRTOT overlayed
    df<-data.frame(time=dates[1:10])
    df=cbind(df,data.frame(MEAN=rowMeans(PV,na.rm=T)[1:10]))
    df=cbind(df,setNames(data.frame(rowQuantiles(PV, probs = c(0.25,0.5,0.75),na.rm=T)[1:10,]), c("Q25", "Q50", "Q75"))) # fancy way to define data frame names upon creation :)
    df=cbind(df,data.frame(PVRTOT=rowMeans(PVRTOT,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRLS=rowMeans(PVRLS,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRTURBM=rowMeans(PVRTURBM,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRTURBT=rowMeans(PVRTURBT,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRCONVT=rowMeans(PVRCONVT,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRCONVM=rowMeans(PVRCONVM,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRLWH=rowMeans(PVRLWH,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRLWC=rowMeans(PVRLWC,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRCOND=rowMeans(PVRCOND,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRDEP=rowMeans(PVRDEP,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVREVR=rowMeans(PVREVR,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVREVC=rowMeans(PVREVC,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRSUBS=rowMeans(PVRSUBS,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRMELTS=rowMeans(PVRMELTS,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRFRZ=rowMeans(PVRFRZ,na.rm=T)[1:10]))
    df=cbind(df,data.frame(PVRRIME=rowMeans(PVRRIME,na.rm=T)[1:10]))
    
    p0<-ggplot(df,aes(x=time, y=MEAN)) +
      geom_ribbon(aes(ymin=Q25,ymax=Q75),alpha=0.5,fill="gray") +
      geom_line(aes(y=Q50),lwd=2,col="gray") +
      geom_line(lwd=1,col="blue") +
      geom_line(aes(y=PVRTOT,color="PVRTOT"),lwd=1.5) +
      geom_line(aes(y=PVRTURBT,color="PVRTURBT"),lwd=1) +
      geom_line(aes(y=PVRTURBM,color="PVRTURBM"),lwd=1,linetype = "dashed") +
      geom_line(aes(y=PVRCONVT,color="PVRCONVT"),lwd=1) +
      geom_line(aes(y=PVRCONVM,color="PVRCONVM"),lwd=1,linetype = "dashed") +
      geom_line(aes(y=PVRLWC,color="PVRLWC"),lwd=1) +
      geom_line(aes(y=PVRLWH,color="PVRLWH"),lwd=1,linetype = "dashed") +
      geom_line(aes(y=PVRCOND,color="PVRCOND"),lwd=1) +
      geom_line(aes(y=PVRDEP,color="PVRDEP"),lwd=1) +
      geom_line(aes(y=PVREVR,color="PVREVR"),lwd=1) +
      geom_line(aes(y=PVREVC,color="PVREVC"),lwd=1) +
      geom_line(aes(y=PVRSUBS,color="PVRSUBS"),lwd=1) +
      geom_line(aes(y=PVRMELTS,color="PVRMELTS"),lwd=1) +
      geom_line(aes(y=PVRFRZ,color="PVRFRZ"),lwd=1) +
      geom_line(aes(y=PVRRIME,color="PVRRIME"),lwd=1) +
      scale_x_datetime(labels = date_format("%H:%M"), date_breaks = "1 hours") +
      ggtitle(paste("Diagnosed PV Evolution on ",sdate,sep="")) + labs(x="Time along backward trajectory [h]",y="PV [PVU]",color="Legend") +
      theme(legend.position="bottom") + scale_color_manual(values = cmap)
    
    ggsave(filename=paste("/home/atroman/projects/stingjet/rscript/PVR_D",pd,"_",dh,"h_",sdate,".png",sep=""),
           plot=p0)
    
  }
  
  # PV
  df<-data.frame(time=dates[1:10])
  df=cbind(df,data.frame(MEAN=rowMeans(PV,na.rm=T)[1:10]))
  df=cbind(df,setNames(data.frame(rowQuantiles(PV, probs = c(0.25,0.5,0.75),na.rm=T)[1:10,]), c("Q25", "Q50", "Q75"))) # fancy way to define data frame names upon creation :)
  
  p1<-ggplot(df,aes(x=time, y=MEAN)) +
    geom_ribbon(aes(ymin=Q25,ymax=Q75),alpha=0.5,fill="gray") +
    geom_line(aes(y=Q50),lwd=2,col="gray") + geom_line(lwd=1,col="blue") +
    scale_x_datetime(labels = date_format("%H:%M"), date_breaks = "1 hours") + ylim(-0.2,1) +
    ggtitle("Potential Vorticity") + ylab("PV [PVU]") + xlab("Time along backward trajectory [h]")
  
  # Pressure
  df<-data.frame(time=dates[1:10])
  df=cbind(df,data.frame(MEAN=rowMeans(p,na.rm=T)[1:10]))
  df=cbind(df,setNames(data.frame(rowQuantiles(p, probs = c(0.25,0.5,0.75),na.rm=T)[1:10,]), c("Q25", "Q50", "Q75"))) # fancy way to define data frame names upon creation :)
  
  p2<-ggplot(df,aes(x=time, y=MEAN)) +
    geom_ribbon(aes(ymin=Q25,ymax=Q75),alpha=0.5,fill="gray") +
    geom_line(aes(y=Q50),lwd=2,col="gray") + geom_line(lwd=1,col="blue") + 
    scale_x_datetime(labels = date_format("%H:%M"), date_breaks = "1 hours") + ylim(950,650) +
    ggtitle("Pressure") + ylab("p [hPa]") + xlab("Time along backward trajectory [h]")
  
  # Wind
  df<-data.frame(time=dates[1:10])
  df=cbind(df,data.frame(MEAN=rowMeans(WND,na.rm=T)[1:10]))
  df=cbind(df,setNames(data.frame(rowQuantiles(WND, probs = c(0.25,0.5,0.75),na.rm=T)[1:10,]), c("Q25", "Q50", "Q75"))) # fancy way to define data frame names upon creation :)
  
  p3<-ggplot(df,aes(x=time, y=MEAN)) +
    geom_ribbon(aes(ymin=Q25,ymax=Q75),alpha=0.5,fill="gray") +
    geom_line(aes(y=Q50),lwd=2,col="gray") + geom_line(lwd=1,col="blue") + 
    scale_x_datetime(labels = date_format("%H:%M"), date_breaks = "1 hours") + ylim(0,55) +
    ggtitle("Wind") + ylab("Wind [m/s]") + xlab("Time along backward trajectory [h]")
  
  # Potential temperature
  df<-data.frame(time=dates[1:10])
  df=cbind(df,data.frame(MEAN=rowMeans(TH,na.rm=T)[1:10]))
  df=cbind(df,setNames(data.frame(rowQuantiles(TH, probs = c(0.25,0.5,0.75),na.rm=T)[1:10,]), c("Q25", "Q50", "Q75"))) # fancy way to define data frame names upon creation :)
  
  p4<-ggplot(df,aes(x=time, y=MEAN)) +
    geom_ribbon(aes(ymin=Q25,ymax=Q75),alpha=0.5,fill="gray") +
    geom_line(aes(y=Q50),lwd=2,col="gray") + geom_line(lwd=1,col="blue") + 
    scale_x_datetime(labels = date_format("%H:%M"), date_breaks = "1 hours") + ylim(278,288) +
    ggtitle("Potential Temperature") + ylab("TH [K]") + xlab("Time along backward trajectory [h]")
  
  # Fix lon and lat position, relative to movement of cyclone
  for(i in 1:10) {
    londiff=cypos$lon[i]-cypos$lon[1]
    latdiff=cypos$lat[i]-cypos$lat[1]
    # Add difference to all instances of this hour
    LON[i,]=LON[i,]-londiff
    LAT[i,]=LAT[i,]-latdiff
  }
  
  # Plot trajectories
  # df<-data.frame(traj=rep(seq(1:length(selnew)),each=10),lon=c(LON[1:10,]),lat=c(LAT[1:10,]),p=c(P[1:10,]),w=c(WND[1:10,]))
  # df=cbind(df,data.frame(col=cut(df$p,seq(600,1000,25))))
  # p5<-ggplot(df, aes(lon, lat)) + geom_path(aes(group = traj, colour=col)) +
  #   scale_color_manual(values=get_brewer_pal(palette = "RdYlBu", n = 18)) +
  #   theme(legend.position = "none") +
  #   guides(fill = guide_colourbar())
  
  # Plot trajectories, attempt 2
  df<-data.frame(traj=rep(seq(1:length(selnew)),each=10),lon=c(LON[1:10,]),lat=c(LAT[1:10,]),p=c(P[1:10,]),w=c(WND[1:10,]))
  p5<-ggplot(df, aes(lon, lat)) + geom_path(aes(group = traj,color=p)) +
    scale_colour_distiller(guide="colourbar",palette="RdYlBu",limits=c(650,950))
    
 # ggsave(filename=paste("/home/atroman/projects/stingjet/rscript/TRA_",sdate,".png",sep=""),
 #        plot=annotate_figure( ggarrange(ggarrange(p1, p3, p4,nrow=3,ncol=1), ggarrange(p2, p5,ncol=1,nrow=2,heights = c(1,2)), ncol=2,nrow=1),
#                  top = text_grob(sdate, face = "bold", size = 14)))
  
  # Delta P 75hPa
  # ggsave(filename=paste("/home/atroman/projects/stingjet/rscript/DESCEND_",sdate,".png",sep=""),
  #        plot=annotate_figure( ggarrange(ggarrange(p1, p3, p4,nrow=3,ncol=1), ggarrange(p2, p5,ncol=1,nrow=2,heights = c(1,2)), ncol=2,nrow=1),
  #                              top = text_grob(paste(length(sel)," Trajectories with ΔP> 75hPa on ",sdate,sep=""), face = "bold", size = 14)))
  
  ggsave(filename=paste("/home/atroman/projects/stingjet/rscript/D",pd,"_",dh,"h_",sdate,".png",sep=""),
         plot=annotate_figure( ggarrange(ggarrange(p1, p3, p4,nrow=3,ncol=1), ggarrange(p2, p5,ncol=1,nrow=2,heights = c(1,2)), ncol=2,nrow=1),
                               top = text_grob(paste(nvals," Trajectories with ΔP",dh,"h≥",pd,"hPa on ",sdate,sep=""), face = "bold", size = 14)))
  
}

















plot(PVmeans,t="l")

test <- rowMeans(sapply(PVlist,function(x) unlist(x[,"PV"])),na.rm=T)

# PVvals<-unlist(PVlist)
# Mvals<-unlist(Mlist)

ggplot(PVvals,aes(x=time,y=PV)) + geom_line()

test<-do.call("rbind", PVlist)

# Need new sequence
exseq<-seq(1,length(dataPV$time),21)

# Remove trajectories with NA
rem<-which(is.na(dataPV$lon[exseq+20]))

for(r in rem) {
  row=exseq[r]
  dataPV<-dataPV[-(row:(row+20)),]
  dataM<-dataM[-(row:(row+20)),]
}

# Plot these trajectories




trajs_all<-list()
PVtend_all<-list()

for (i in 1:length(dates)) {
  
  # Convert dates to useful one
  date=dates[i]
  
  cat("Now working on",sdate,"\n")
  
 
  
  
  # Iterate through features
  for (f in 1:length(features)) {
    
    if(f==5) {
      pick=2
    } else {
      pick=1
    }
    
    # Define feature
    feat=features[f]
    
    # Read cluster info from disk
    clusters=read.csv2(paste("/net/thermo/atmosdyn/atroman/phd/PAC1d/clusters/",feat,"_",sdate,".csv",sep=""),sep=",")
    clusters=clusters[,-1]
    
    # Only pick one cluster
    sel<-clusters$selpos[which(clusters$clusterID==pick)]
    
    # Create array
    trajs<-array(NA,dim=c(length(sel),25))
    PVtend<-array(NA,dim=c(length(sel),24))
    
    # Save trajectory data
    for(t in seq(1,length(sel),1)) {
      
      # select trajectory
      trajectory=data[(exseq[sel[t]]):(exseq[sel[t]]+24),]
      
      # save data
      trajs[t,]<-trajectory$PV
      
      # save tendencies
      pvrtot<-trajectory$PVRTURB+trajectory$PVRCONV+trajectory$PVRLWC+trajectory$PVRLWH+trajectory$PVRSW+trajectory$PVRLS
      pvrtend<-trajectory$PV[25]+pvrtot[24]
      for(j in 2:24) {
        pvrtend[j]=pvrtend[j-1]+pvrtot[25-j]
      }
      PVtend[t,]=rev(pvrtend)
    }

    # check if each feature was already filled at least once
    if(length(trajs_all)>=length(features)) {
       trajs_all[[f]]=rbind(trajs_all[[f]],trajs)
       PVtend_all[[f]]=rbind(PVtend_all[[f]],PVtend)
     } else {
       trajs_all[[f]]=trajs
       PVtend_all[[f]]=PVtend
     }
    
  } # features
  
} # dates

# Plot resulting statistics
for (f in 1:7) {
  
  # Define feature
  feat=features[f]
  
  # Compute statistics over all rows
  meanfull<-apply(trajs_all[[f]], 2, mean)
  quantfull<-apply(trajs_all[[f]], 2, quantile)
  
  meanpvr<-apply(PVtend_all[[f]], 2, mean)
  quantpvr<-apply(PVtend_all[[f]], 2, quantile)
  
  # Derive time when at least 80% of anomaly is build up
  PV80=(quantfull[3,1]-quantfull[3,25])*0.8
  PVthres=quantfull[3,1]-PV80
  PVdevs=quantfull[3,]-PVthres
  thres80=which.min(abs(PVdevs))
  
  PV75=(quantfull[3,1]-quantfull[3,25])*0.75
  PVthres=quantfull[3,1]-PV75
  PVdevs=quantfull[3,]-PVthres
  thres75=which.min(abs(PVdevs))
  
  pdf(paste("/home/atroman/phd/plots/b0ck_PAC1d/evo_",feat,sep=""),width=6,height=6)
  plot(meanfull,t="l",lwd=2,ylim=c(-0.5,2),main=paste(feat," cluster ","1 ",length(trajs_all[[f]][,1])," trajs",sep=""),xlab="Hours",ylab="PV")
  lines(quantfull[2,],col="blue")
  lines(quantfull[4,],col="blue")
  lines(quantfull[3,],col="red",lwd=2)
  lines(quantpvr[3,],col="red",lwd=2,lty=2)
  lines(meanpvr,col="black",lwd=2,lty=2)
  abline(v=thres80,lty=2)
  abline(v=thres75,lty=3)
  dev.off()
  
}

