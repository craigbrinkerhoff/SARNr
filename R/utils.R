#################################
## UTILITY FUNCTIONS
## Winter 2022
## Craig Brinkerhoff
##################################

#' Spatial erase function
#' 
#' Homebaked sf function to mimic the Erase tool in ArcGIS
#' 
#' @param  x: layer to erase things away from
#' @param y: overlaying layer that defines the 'erase zones'
#' 
#' @name st_erase

#' @import sf
#' 
#' @return result of erase function
#'
#' @export
st_erase = function(x, y){
  return(st_difference(x, st_union(st_combine(y))))
}

#' "not in" function
`%notin%` <- Negate(`%in%`)

#' Classifies water
#' 
#' Classifies a multi-band image into water/not water using Rosin's unimodal thresholding algorithm + an elevation cutoff.
#' 
#' @name sarn_classifyWater_unimodal
#' 
#' @param img: Multi-band RS image to be classified. Required band names are 'green', 'nir', and 'red'.
#' @param dem: DEM for elevation cutoff of same resolution as RS image
#' @param maxElev: Maximum elevation for water (in meters). Default=4000
#' 
#' @return Binary river classification: 1 is water, 0 is land
#' 
#' @export
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
  
  img_fin[img_fin == 0] <- NA
  
  return(img_fin)
}

#' Calculate stream order along network
#'
#' Given a sarn network, calculate the Strahler stream order. Note that this function was adapted (and simplified) from the hydrostreamer R package implementation of strahler stream order in R (https://github.com/mkkallio/hydrostreamer)
#'
#' @name calcStrahlerOrder
#'
#' @param river: river networks as sf object
#' 
#' @return sf object river network, with stream order as an attribute
#' 
#' @export calcStrahlerOrder
calcStrahlerOrder <- function(river){
  from <- river$from
  to <- river$to
  nUp <- river$nUp
  
  n_seg <- nrow(river)
  strahler <- rep(1, n_seg) #initial estimate of stream order
  rounds_with_no_edits <- 0
  edits <- 1
  
  while (rounds_with_no_edits < 2) { #run until no longer edited
    if (edits == 0) rounds_with_no_edits <- rounds_with_no_edits+1
    if (rounds_with_no_edits == 2) break
    edits <- 1
    # run for every river segment
    for (seg in 1:n_seg) {
      
      n_sources <- length(which(to == from[seg]))

      # check if the segment is headwaters (no inflowing segments)
      if (n_sources == 0 && is.na(nUp[seg]) == 1) {
        
        #do nothing, leave as first order
        
      } else if (n_sources == 1 && is.na(nUp[seg]) != 1) {
        # if there is a single upstream reach
        #prev_seg <- from[seg]
        row <- from[which(to == from[seg])]

        # if the current stream order DOES NOT EQUAL TO inflowing 
        # stream order
        if ((!strahler[seg] == strahler[row]) & is.na(strahler[row])==0){ #from IDs could be referring to removed dangles (and thus are NA, so handle that)
          strahler[seg] <- strahler[row]
          edits <- edits+1
        }
        
      } else {
        # if there are multiple inflowing reaches
        prev_segs <- which(to == from[seg])
        str <- strahler[which(to == from[seg])]
        max_value <- max(str)
        n_max_values <- table(str)[as.character(max_value)]
        
        if (n_max_values == 1) {
          if (!strahler[seg] == max_value) {
            strahler[seg] <- max(str)
            edits <- edits+1
          }
        } else {
          if (!strahler[seg] == max_value+1) {
            strahler[seg] <- max(str)+1
            edits <- edits+1
          }
        }
        
      }
    }
    edits <- edits-1
    
  }
  
  #add to river network
  test <- any(names(river) == "STRAHLER")
  if(test) {
    river <- river[,-"STRAHLER"]
    river <- tibble::add_column(river, 
                                STRAHLER = strahler, 
                                .before=length(names(river)))
    message("Replacing the existing column 'STRAHLER'.")
  } else {
    river <- tibble::add_column(river, 
                                STRAHLER = strahler, 
                                .before=length(names(river)))
  }
  
  return(river)
}
