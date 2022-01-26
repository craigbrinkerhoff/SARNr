# UTILITY FUNCTIONS
# Winter 2022

#' Spatial erase function
#' 
#' Homebaked sf function to mimic the Erase tool in ArcGIS
#' 
#' @param  x: layer to erase things away from
#' @param y: overlaying layer that defines the 'erase zones'
#' 
#' @import sf
st_erase = function(x, y) {
  st_difference(
    st_geometry(x) %>% st_buffer(0), 
    st_union(st_combine(st_geometry(y))) %>% st_buffer(0)
  )
}

#' "not in" function
`%notin%` <- Negate(`%in%`)

#' Classifies water
#' 
#' Classifies a multi-band image into water/not water using Rosin's unimodal thresholding algorithm + an elevation cutoff.
#' 
#' @param img: Multi-band RS image to be classified. Required band names are 'green', 'nir', and 'red'.
#' @param dem: DEM for elevation cutoff of same resolution as RS image
#' @param maxElev: Maximum elevation for water (in meters). Default=4000
#' 
#' @import terra
#' 
#' @return Binary river classification: 1 is water, 0 is land
#' 
#' @export sarn_classifyWater_unimodal
sarn_classifyWater_unimodal <- function(img, dem, maxElev=4000) {
  #CHECK BAND NAMES
  checkRS(img)
  
  #CALCULATE SPECTRAL INDEX (NDWI - NDVI following https://doi.org/10.3390/s18082580)
  values <- ((img$green - img$nir)/(img$green + img$nir)) - ((img$nir - img$red)/(img$nir + img$red))
  
  #CALCULATE ROSIN'S THRESHOLD FOLLOWING https://doi.org/10.1016/j.rse.2017.03.044
  #CALCULATE GAUSSIAN DENSITY DISTRIBUTION
  for_gaussian <- values(values)
  for_gaussian <- for_gaussian[is.na(for_gaussian)==0]
  d <- density(for_gaussian) #Gaussian kernel density function
  
  hst <- data.frame('DN'=d$x, 'freq'=d$y)
  peak <- c(hst[which.max(hst$freq),]$DN, max(hst$freq))
  max <- c(max(hst$DN), hst[which.max(hst$DN),]$freq)
  
  sample <- hst[which(hst$DN >= peak[1]),]
  
  #LINEAR INTERPOLATION
  x <- c(peak[1], max[1])
  y <- c(peak[2], max[2])
  data_approx <- approx(x, y, n=nrow(sample))
  
  #FIND BREAKPOINT
  diff <- data_approx$y - sample$freq
  threshold <- sample[which.max(diff),]
  img_fin <- values >= threshold$DN
  
  #REMOVE HIGH-ELEVATIONS
  dem <- dem <= maxElev
  img_fin <- img_fin * dem
  
  return(img_fin)
}

#' Classifies water
#' 
#' Classifies a multi-band image into water/not water using Otsu's bimodal thresholding algorithm + an elevation cutoff.
#' 
#' @param img: Multi-band RS image to be classified. Required band names are 'green', 'nir', and 'red'
#' @param dem: DEM for elevation cutoff of same resolution as RS image
#' @param maxElev: Maximum elevation to allow water to exist in meters. Use to avoid ice/snow/glaciers
sarn_classifyWater_bimodal <- function(img, dem, maxElev=4000) {
  print('get from guthub again')
}
