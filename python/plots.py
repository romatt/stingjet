#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov 12 09:54:21 2020

@author: atroman
"""

# IMPORT MODULES

import cartopy.crs as ccrs # cartopy plots
import cartopy.feature as cfeature # for adding features to plots
import numpy as np # for arrays
import xarray as xr # for netcdf
import matplotlib.pyplot as plt # for plots

# Define a Cartopy 'ordinary' lat-lon coordinate reference system.
crs_latlon = ccrs.PlateCarree()

# Define a window for plotting
plonmin = -22
plonmax = -20
platmin = 48.5
platmax = 50.5

# NetCDF Files handles
f_APV = '/net/thermo/atmosdyn2/atroman/stingjet/tra_01/APV20140212_02_8h.nc'
f_P = '/net/thermo/atmosdyn2/atroman/stingjet/cdf_01/P20140212_02'

# load data
d_APV = xr.open_dataset(f_APV)
# Read coordinates
lon, lat, lev = d_APV.lon.values, d_APV.lat.values, d_APV.lev.values

sellon=np.where((lon <= plonmax) & (lon >= plonmin))[0]
sellat=np.where((lat <= platmax) & (lat >= platmin))[0]

# Only read necessary data

#PV_DIFF = d_APV.PV_DIFF.values[0,17,sellat,sellon]
PV_DIFF = d_APV.PV_DIFF.values[0,17,sellat[0]:sellat[len(sellat)-1]+1,sellon[0]:sellon[len(sellon)-1]+1]
APVTOT = d_APV.APVTOT.values[0,17,sellat[0]:sellat[len(sellat)-1]+1,sellon[0]:sellon[len(sellon)-1]+1]
APVRES = d_APV.APVRES.values[0,17,sellat[0]:sellat[len(sellat)-1]+1,sellon[0]:sellon[len(sellon)-1]+1]
#PV_DIFF, APVTOT, APVRES = d_APV.PV_DIFF.values[0,:,sellat,sellon], d_APV.APVTOT.values, d_APV.APVRES.values

d_P = xr.open_dataset(f_P)
lon_P, lat_P = d_P.lon.values, d_P.lat.values

sellon2=np.where((lon_P <= plonmax) & (lon_P >= plonmin))[0]
sellat2=np.where((lat_P <= platmax) & (lat_P >= platmin))[0]

U = d_P.U.values[0,17,sellat2[0]:sellat2[len(sellat2)-1]+1,sellon2[0]:sellon2[len(sellon2)-1]+1]
V = d_P.V.values[0,17,sellat2[0]:sellat2[len(sellat2)-1]+1,sellon2[0]:sellon2[len(sellon2)-1]+1]

WIND = np.sqrt(U**2+V**2)

# Get an overview over dataset by simply typing
#data_APV

#print(APVTOT.shape)

# Generate figure
fig, axes = plt.subplots(1, 3, subplot_kw=dict(projection=ccrs.PlateCarree()))
#fig = plt.figure()

# Define figure size
fig.set_figheight(10)
fig.set_figwidth(15)

# Add projection and land-masks
#ax = plt.axes(projection=ccrs.PlateCarree())
axes[0].add_feature(cfeature.LAND,color="lightgray")

# Plot1
filled_PV = axes[0].contourf(lon[sellon],lat[sellat],PV_DIFF,levels=np.arange(-7.5,7.5,0.5),cmap="RdBu_r",transform=crs_latlon)
lines_wind = axes[0].contour(lon_P[sellon2],lat_P[sellat2],WIND,levels=np.arange(40,60,2.5),cmap="binary",transform=crs_latlon)
axes[0].clabel(lines_wind,colors=['black'],manual=False,inline=True)

#Plot2
filled_PV = axes[1].contourf(lon[sellon],lat[sellat],APVTOT,levels=np.arange(-7.5,7.5,0.5),cmap="RdBu_r",transform=crs_latlon)
lines_wind = axes[1].contour(lon_P[sellon2],lat_P[sellat2],WIND,levels=np.arange(40,60,2.5),cmap="binary",transform=crs_latlon)
axes[1].clabel(lines_wind,colors=['black'],manual=False,inline=True,fmt=' {:.1f} '.format)

#Plot3
filled_PV = axes[2].contourf(lon[sellon],lat[sellat],APVRES,levels=np.arange(-7.5,7.5,0.5),cmap="RdBu_r",transform=crs_latlon)
lines_wind = axes[2].contour(lon_P[sellon2],lat_P[sellat2],WIND,levels=np.arange(40,60,2.5),cmap="binary",transform=crs_latlon)
axes[2].clabel(lines_wind,colors=['black'],manual=False,inline=True)

#fig.colorbar(filled_PV, orientation='horizontal')



# Combined colorbar
cbar=fig.colorbar(filled_PV, ax=axes.ravel().tolist(),orientation='horizontal')
