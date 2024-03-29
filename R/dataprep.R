#####################################
## ERROR HANDLING AND OBJECT GENERATION FUNCTIONS
## Winter 2022
## Craig Brinkerhoff
###################################

#' Make sarndata object
#'
#' Make a sarndata object to run the actual algorithm on. Checks input data projections and formats too.
#' 
#' @name sarn_data
#' 
#' @param dem_network: DEM-generated river network (shapefile)
#' @param riverMask: River classification raster
#' @param dem: Digital elevation model that generated dem_network
#' 
#' @return sarndata object
#' 
#' @export sarn_data
sarn_data <- function(dem_network, riverMask, dem) {
  
  #INPUT DATA FORMAT AND PROJECTION CHECKING
  #ensure all shapefiles are sf::sf objects
  checkShp(dem_network)

  #ensure dem and river masks are both terra::spatRaster objects
  checkRast(riverMask)
  checkRast(dem)
  
  #make sure river mask is composed of 1s and NaNs
  checkMask(riverMask)
  
  #Ensure reach IDs are setup right (if not, correct them)
  checkCat(dem_network)

  #make sure all inputs are in the same projection
  checkProj(dem_network, riverMask, dem)
  
  #produce sarn object
  datalist <- list(dem_network = dem_network,
                   riverMask = riverMask,
                   dem = dem)
  
  out <- structure(c(datalist),
                   class = c("sarndata"))
  return(out)
}

#' Check shapefile object type
#' 
#' Ensures that shapefiles are sf objects
#'
#' @name checkShp
#' 
#' @param shapefile: shapefile to be used in SARNr
#' 
#' @return NULL
#' 
#' @export
checkShp <- function(shapefile) {
  if(class(shapefile)[1] != 'sf'){
    stop("All shapefiles must be sf objects!")
  }
}

#' Check raster object type
#' 
#' Ensures that rasters are terra objects
#'
#' @name checkRast
#' 
#' @param raster: raster to be used in SARNr
#'
#' @return NULL
#' 
#' @export
checkRast <- function(raster) {
  if(class(raster)[1] != 'SpatRaster'){
    stop("All rasters must be Terra objects!")
  }
}

#' Network ID column check
#' 
#' Ensures the shapefile ID column is named 'cat'. If it does not exist, create one
#' 
#' @name checkCat
#' 
#' @param shapefile: shapefile to be used in SARNr
#'
#' @return null
#' 
#' @export
checkCat <- function(shapefile) {
  if("cat" %notin% colnames(shapefile)) {
    shapefile$cat <- 1:nrow(shapefile)
  }
}

#' Check input data projection
#' 
#' Ensures raster and vector input data are all in the same projection
#' 
#' @name checkProj
#' 
#' @import raster
#' @import terra
#' 
#' @param dem_network: vector dem river network to be used in SARNr
#' @param rs_raster: raster water mask to be used in SARNr
#' @param dem_full: raster dem to be used in SARNr
#' 
#' @return NULL
#' 
#' @export
checkProj <- function(dem_network, rs_raster, dem_full){
  dem <- as.character(crs(dem_network, proj=TRUE))
  rast <- crs(rs_raster, proj=TRUE)
  rast_dem <- crs(dem_full, proj=TRUE)
  
  if(dem != rast || dem != rast_dem || rast != rast_dem){
    stop('All inputs must be in the same projection!!')
  }
}

#' Check RS band names
#' 
#' Ensures that band names are correct before calculating spectral indices
#' @name checkRS
#'
#' @param img: remote sensing image to be used in SARNr
#' 
#' @return NULL
#' 
#' @export
checkRS <- function(img){
  bandNames <- names(img)
  
  if(any(bandNames %notin% c('blue', 'red', 'green', 'nir'))) {
    stop('Bands must be named blue, red, green, and nir!! The order does not matter, just the names')
  }
}

#' Check river mask format
#' 
#' Ensures that river mask is binary composed of only 1s and NaNs
#' 
#' @name checkMask
#' 
#' @param mask: raster river mask
#' 
#' @return NULL
#' 
#' @export
checkMask <- function(mask){
  temp <- values(mask)[,1]
  if(any(is.nan(temp)==0 & temp != 1)){
    stop('River mask must be composed of only 1s and NaNs!!!')
  }
}
