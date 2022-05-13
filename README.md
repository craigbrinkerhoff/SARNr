# SARNr: Efficiently extract actively-flowing drainage networks from Planet imagery

`SARNr` is an R implementation of a modified version of the SARN algorithm. SARN is an Arcpy algorithm developed by Xin Lu and Kang Yang at Nanjing University to map actively flowing drainage networks by combining Sentinel-2 water masks and a DEM-based river network. See the below paper for more.

Lu, X., Yang, K., Lu, Y., Gleason, C.J., Smith, L.C., & Li, M. (2020). Small Arctic rivers mapped from Sentinel-2 satellite imagery and ArcticDEM. Journal of Hydrology, 584, 124689

`SARNr` takes this algorithm and rewrites it in R such that you 1) don't need an ArcGIS license, and 2) can easily be farmed out to parallel workers and dramatically increase processing speeds. We also make some minor changes to the algorithm itself, namely 1) the pre-processing/network joining functions, and 2) water classification methods. Crucially, we also add automated hydrography generation tools to automatically clean and build topologically consistent, routable river networks. However, the core of the SARN algorithm (clipping the network to the RS rivers) is maintained.

## To install
Note that one of the package dependencies (`sfnetworks`) requires R 3.6.0.

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

Note that the `terra` package auto loaded `sp` and `raster` libraries into the namespace. Depending on your setup, you might need to manually specify these.

## To use
Check the Introduction vignette at `vignette('introduction', package="SARNr')`.
