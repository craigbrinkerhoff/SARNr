# ERROR HANDLING AND OBJECT GENERATION FUNCTIONS
# Winter 2022

#' Produce SARNr object
#'
#' Produces an SARNr object to use to run the actual algorithm
#' 
#' @param dem_network: DEM-generated river network as a shapefile
#' @param riverMask: River classification raster
#' @param dem: Digital elevation model that generated the dem_network
sarn_data <- function(dem_network, riverMask, dem) {
  
  #ensure all shapefiles are sf objects
  checkShp(dem_network)

  #ensure dem is a terra raster
  checkRast(riverMask)
  checkRast(dem)
  
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
#' @param shapefile: shapefile to be used in SARNr
checkShp <- function(shapefile) {
  if(class(shapefile)[1] != 'sf'){
    stop("All shapefiles must be sf objects!")
  }
}

#' Check raster object type
#' 
#' Ensures that rasters are terra objects
#' 
#' @param raster: raster to be used in SARNr
checkRast <- function(raster) {
  if(class(raster)[1] != 'SpatRaster'){
    stop("All rasters must be Terra objects!")
  }
}

#' Network ID column chekc
#' 
#' Ensures the shapefile ID column is named 'cat'. If it doesnt exist, create one
checkCat <- function(shapefile) {
  if("cat" %notin% colnames(shapefile)) {
    shapefile$cat <- 1:nrow(chapefile)
  }
}

#' Check input data projection
#' 
#' Ensures raster and vector river networks are in the same projection
checkProj <- function(dem_network, rs_raster, dem_full){
  dem <- as.character(crs(dem_network))
  rast <- crs(rs_raster, proj=TRUE)
  rast_dem <- crs(dem_full, proj=TRUE)
  
  if(dem != rast || dem != rast_dem || rast != rast_dem){
    stop('All inputs must be in the same projection!!')
  }
}
