# FUNCTIONS TO BUILD HYDROGRAPHY PRODUCT
# winter 2022




#' Builds usable hydrography from SARN
#' 
#' Builds a routing framework and calculates common river network parameters from the SARN output. Note this this creates a temp file to convert between sf and terra vector objects...
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
#' @import hydrostreamer
#'
#' @returns final hydrography product representing the actively-flowing river network with 1) a routing table, 2) reach slope, 3) stream order, and 4) reach length
sarn_hydrography <- function(trimmedNetwork, dem, riverMask, lengthThresh, printOutput='Yes') {
  
  printOutput <- ifelse(printOutput == 'yes' || printOutput == 'Yes', 1, 0)
  
  #CREATE NETWORK TOPOLOGY (ROUTING TABLE) USING SFNETWORKS PACKAGE
    #this also iteratively removes dangling segments shorter than the length threshold until non are left
  flag <- 1
  while(flag != 0){
    hydrography <- as_sfnetwork(trimmedNetwork)
    smoothed = convert(hydrography, to_spatial_smooth) #SMOOTH 'PSEUDO-NODES', I.E. DISSOLVE ALL RS/DEM SUB-REACHES WITHIN A TOPOLOGICALLY-DEFINED REACH
    hydrography_shp <- smoothed %>%
      activate("edges") %>%
      st_as_sf() %>%
      select(-c('reachID', 'geometry'))
    hydrography_shp$reachID <- 1:nrow(hydrography_shp)
    
    #ADD NUMBER UPSTREAM RIVERS
    nup <- group_by(hydrography_shp, to) %>%
      summarise(nUp=n())
    nup <- as.data.frame(nup)
    nup <- select(nup, 'to', 'nUp')
    colnames(nup) <- c('from', 'nUp') #re-assign nUp to the next downstream reach
    hydrography_shp <- left_join(hydrography_shp, nup, by='from')
    
    hydrography_shp$length <- as.numeric(st_length(hydrography_shp))
    eraseRivers <- hydrography_shp[hydrography_shp$length < lengthThresh & is.na(hydrography_shp$nUp) ==1 ,]
    trimmedNetwork <- filter(hydrography_shp, reachID %notin% eraseRivers$reachID)
    trimmedNetwork <- select(trimmedNetwork, c('reachID', 'geometry'))
    
    flag <- nrow(hydrography_shp) - nrow(trimmedNetwork)
    
    if(printOutput == 1){
      print(paste0('removed ', flag, ' artifical dangles'))
    }
  }

  #ADD STREAM ORDER USING HYDROSTREAMER PACKAGE
  so <- river_network(hydrography_shp, riverID = 'reachID')  %>%
    river_hierarchy() %>%
    as.data.frame() %>%
    select(c('reachID', 'STRAHLER'))
  
  hydrography_shp <- left_join(hydrography_shp, so, by='reachID')
  hydrography_shp$length_m <- as.numeric(st_length(hydrography_shp))
  
  hydrography_shp <- select(hydrography_shp, c('from', 'to', 'reachID', 'STRAHLER', 'length_m', 'geometry'))
  colnames(hydrography_shp) <- c('frmNode', 'toNode', 'rchID', 'strOrdr', 'lngth_m', 'geometry')
  
  #ADD NUMBER UPSTREAM RIVERS
  nup <- group_by(hydrography_shp, toNode) %>%
    summarise(nUp=n())
  nup <- as.data.frame(nup)
  nup <- select(nup, 'toNode', 'nUp')
  colnames(nup) <- c('frmNode', 'nUp') #re-assign nUp to the next downstream reach
  hydrography_shp <- left_join(hydrography_shp, nup, by='frmNode')
  
  #ADDITIONAL FLAGS
  hydrography_shp$headwaterFlag <- ifelse(is.na(hydrography_shp$nUp)==1, 1, 0)
  
  #ADD REACH SLOPE (must be done using terra so need to write to temp file, then read back in as a terra object...)
  f <- file.path(tempdir(), "R_SARN_temp.shp")

  st_write(hydrography_shp, f, delete_dsn=TRUE, quiet = TRUE)
  hydrography_terra <- vect(f)
   
  max_elev <- extract(dem, hydrography_terra, fun=function(x){max(x, na.rm=T)})
  colnames(max_elev) <- c('row', 'max_elv_m')
  min_elev <- extract(dem, hydrography_terra, fun=function(x){min(x, na.rm=T)})
  colnames(min_elev) <- c('row', 'min_elv_m')
   
  slopes <- left_join(max_elev, min_elev, by='row') %>%
   select(!c('row'))
   
  hydrography_shp$slope <- (slopes$max_elv_m - slopes$min_elv_m) / hydrography_shp$lngth_m
   
  #ADD PERCENT OF REACH REMOTELY SENSED (USING WATER MASK)
  perc_RS <- extract(riverMask, hydrography_terra, fun=function(x){mean(x, na.rm=T)}) #average of binary pixels will give a 'percent RS'
  colnames(perc_RS) <- c('ID', 'RS_perc')
  hydrography_shp$RS_perc <- perc_RS$RS_perc
  
  return(hydrography_shp)
}