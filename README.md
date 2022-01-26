# SARNr: Extract Actively-Flowing Drainage Networks from Remotely Sensed Imagery

This in an introduction to the `SARNr` package. SARN is an Arcpy algorithm developed by Xin Lu and Kang Yang at Nanjing University to map actively flowing drainage networks by combining RS rivers and a DEM-based river network. The idea is to merge RS and DEM river networks, using the DEM network to fill in the gaps between the remotely sensed rivers. The network is also trimmed back such that the 'points of emergence' correspond to RS rivers. SARN was specifically developed for 10m Sentinel-2 imagery. See the below paper for more.

Lu, X., Yang, K., Lu, Y., Gleason, C.J., Smith, L.C., & Li, M. (2020). Small Arctic rivers mapped from Sentinel-2 satellite imagery and ArcticDEM. Journal of Hydrology, 584, 124689

`SARNr` takes this algorithm and rewrites it in an open-source language and a self-contained package such that is can be farmed out to run in parallel and dramatically increase processesing speeds. We also make some minor changes to the algorithm itself, namely the pre-processing/joining functions, water classification method, and hydrography generation method. However, the actual network clipping is verbatim the SARN method.

## To install
Note that one of the package dependencies (`sfnetworks`) requires R 3.6

``` R
# First get devtools package
if (!require("devtools")) {
  install.packages("devtools")
  library("devtools")
}

#install SARNr
Sys.setenv(TAR = "/bin/tar") #if using a Linux machine (apparently)...
devtools::install_github("craigbrinkerhoff/SARNr", ref='main', force=TRUE)
```

## To use
See the Introduction vignette at `/vignettes/introduction.html`.
