#########################
## FUNCTIONS TO BUILD HYDROGRAPHY PRODUCT
## Summer 2022
## Craig Brinkerhoff
##########################



#' Builds actively flowing hydrography from SARN
#' 
#' Builds a routing framework and calculates common river network parameters for the river network.
#' 
#' @name sarn_hydrography
#' 
#' @param trimmedNetwork: SARNr-trimmed river network. This would be the $trimmedNetwork output from the sarn_trimNetwork() output
#' @param dem: Digital elevation model that was used to generate the DEM river network
#' @param riverMask: river mask raster used to generate the RS river network. This would be $rs_raster from the sarn_data() output
#' @param lengthThresh: minimum reach length allowed in meters
#' @param printOutput: Do you want the results of the iterative trimming to print to console? Default= Yes
#' 
#' @import dplyr
#' @import sf
#' @import sfnetworks
#' @import tidygraph
#'
#' @return final actively-flowing hydrography
#' 
#' @export sarn_hydrography
sarn_hydrography <- function(trimmedNetwork, dem, riverMask, lengthThresh, printOutput='Yes') {
  
  printOutput <- ifelse(printOutput == 'yes' || printOutput == 'Yes', 1, 0)
  
  #CREATE NETWORK TOPOLOGY (ROUTING TABLE) USING SFNETWORKS
    #this also iteratively removes dangling segments shorter than the length threshold until non are left
  flag <- 1
  while(flag != 0){
    hydrography <- as_sfnetwork(trimmedNetwork)
    smoothed = convert(hydrography, to_spatial_smooth) #SMOOTH 'PSEUDO-NODES', I.E. DISSOLVE ALL RS/DEM SUB-REACHES WITHIN A TOPOLOGICALLY-DEFINED REACH
    hydrography_shp <- smoothed %>%
      activate("edges") %>%
      st_as_sf() %>%
      dplyr::select(-c('reachID', 'geometry'))
    hydrography_shp$reachID <- 1:nrow(hydrography_shp)
    
    #ADD NUMBER UPSTREAM RIVERS
    nup <- group_by(hydrography_shp, to) %>%
      summarise(nUp=n())
    nup <- as.data.frame(nup)
    nup <- dplyr::select(nup, 'to', 'nUp')
    colnames(nup) <- c('from', 'nUp') #re-assign nUp to the next downstream reach
    hydrography_shp <- left_join(hydrography_shp, nup, by='from')
    
    hydrography_shp$length <- as.numeric(st_length(hydrography_shp))
    eraseRivers <- hydrography_shp[hydrography_shp$length < lengthThresh & is.na(hydrography_shp$nUp) ==1 ,]
    trimmedNetwork <- filter(hydrography_shp, reachID %notin% eraseRivers$reachID)
    trimmedNetwork <- dplyr::select(trimmedNetwork, c('reachID', 'geometry'))
    
    flag <- nrow(hydrography_shp) - nrow(trimmedNetwork)
    
    if(printOutput == 1){
      print(paste0('removed ', flag, ' artifical dangles'))
    }
  }
  
  hydrography_shp$length_m <- as.numeric(st_length(hydrography_shp)) #don;t know what the length already in there is, but it might not be meters and might not be in the right projection, so we just do it ourselves here
  
  hydrography_shp <- dplyr::select(hydrography_shp, c('from', 'to', 'reachID', 'length_m', 'geometry'))
  colnames(hydrography_shp) <- c('from', 'to', 'rchID', 'lngth_m', 'geometry')
  
  #ADD NUMBER UPSTREAM RIVERS
  nup <- group_by(hydrography_shp, to) %>%
    summarise(nUp=n())
  nup <- as.data.frame(nup)
  nup <- dplyr::select(nup, 'to', 'nUp')
  colnames(nup) <- c('from', 'nUp') #re-assign nUp to the next downstream reach
  hydrography_shp <- left_join(hydrography_shp, nup, by='from')
  
  #STRAHLER STREAM ORDER
  hydrography_shp <- calcStrahlerOrder(hydrography_shp) #see src/utils.R
  
  #ADDITIONAL FLAGS
  hydrography_shp$headwaterFlag <- ifelse(is.na(hydrography_shp$nUp)==1, 1, 0)
  
  #ADD REACH SLOPE (must be done using terra so need to write to temp file, then read back in as a terra object...)
  f <- file.path(tempdir(), "R_SARN_temp.shp")

  st_write(hydrography_shp, f, delete_dsn=TRUE, quiet = TRUE)
  hydrography_terra <- vect(f)
  
  #standard method is max and min slope along reach to be robust against potential DEM errors
  max_elev <- extract(dem, hydrography_terra, fun=function(x){max(x, na.rm=T)})
  colnames(max_elev) <- c('row', 'max_elv_m')
  min_elev <- extract(dem, hydrography_terra, fun=function(x){min(x, na.rm=T)})
  colnames(min_elev) <- c('row', 'min_elv_m')
   
  slopes <- left_join(max_elev, min_elev, by='row') %>%
   dplyr::select(!c('row'))
   
  hydrography_shp$slope <- (slopes$max_elv_m - slopes$min_elv_m) / hydrography_shp$lngth_m
   
  #ADD PERCENT OF REACH THAT IS REMOTELY SENSED (USING WATER MASK)
  perc_RS <- extract(riverMask, hydrography_terra, fun=function(x){mean(x, na.rm=T)}) #average of binary pixels will give a 'percent RS'
  colnames(perc_RS) <- c('ID', 'RS_perc')
  hydrography_shp$RS_perc <- perc_RS$RS_perc
  
  hydrography_shp <- hydrography_shp[, c("rchID","from","to","nUp","headwaterFlag","STRAHLER","lngth_m","slope","RS_perc","geometry")]
  
  return(hydrography_shp)
}
