# #adapted from https://stackoverflow.com/questions/9595117/identify-a-linear-feature-on-a-raster-map-and-return-a-linear-shape-object-using/9643004#9643004
# 
# densify <- function(xy,n=5){
#   ## densify a 2-col matrix
#   cbind(dens(xy[,1],n=n),dens(xy[,2],n=n))
# }
# 
# dens <- function(x,n=5){
#   ## densify a vector
#   out = rep(NA,1+(length(x)-1)*(n+1))
#   ss = seq(1,length(out),by=(n+1))
#   out[ss]=x
#   for(s in 1:(length(x)-1)){
#     out[(1+ss[s]):(ss[s+1]-1)]=seq(x[s],x[s+1],len=(n+2))[-c(1,n+2)]
#   }
#   out
# }
# 
# simplecentre <- function(xyP,dense){
#   require(deldir)
#   require(splancs)
#   require(igraph)
#   require(rgeos)
#   
#   ### optionally add extra points
#   if(!missing(dense)){
#     xy = densify(xyP,dense)
#   } else {
#     xy = xyP
#   }
#   
#   ### compute triangulation
#   d=deldir(xy[,1],xy[,2])
#   
#   ### find midpoints of triangle sides
#   mids=cbind((d$delsgs[,'x1']+d$delsgs[,'x2'])/2,
#              (d$delsgs[,'y1']+d$delsgs[,'y2'])/2)
#   
#   ### get points that are inside the polygon 
#   sr = SpatialPolygons(list(Polygons(list(Polygon(xyP)),ID=1)))
#   ins = over(SpatialPoints(mids),sr)
#   
#   ### select the points
#   pts = mids[!is.na(ins),]
#   
#   dPoly = gDistance(as(sr,"SpatialLines"),SpatialPoints(pts),byid=TRUE)
#   pts = pts[dPoly > max(dPoly/1.5),]
#   
#   ### now build a minimum spanning tree weighted on the distance
#   G = graph.adjacency(as.matrix(dist(pts)),weighted=TRUE,mode="upper")
#   T = minimum.spanning.tree(G,weighted=TRUE)
#   
#   ### get a diameter
#   path = get.diameter(T)
#   
#   if(length(path)!=vcount(T)){
#     stop("Path not linear - try increasing dens parameter")
#   }
#   
#   ### path should be the sequence of points in order
#   list(pts=pts[path,],tree=T)
#   
# }
# 
# onering=function(p){p@polygons[[1]]@Polygons[[1]]@coords}
# 
# #Convert water mask to sp polygons-----------------------------------
# classified <- rast('debug/classified.tif')
# classified_p <- as.polygons(classified) #convert to vector
# classified_p <- disaggregate(classified_p) #dissagregate polygons
# classified_p <- classified_p[classified_p$green == 1,] #only keep water polygons
# classified_p <-  as(classified_p, "Spatial") #convert to sp object
# 
# #Run vector skeletonization algorithm---------------------------------
# scp = simplecentre(onering(classified_p[23,]))
# plot(classified_p[23,])
# lines(scp$pts,col="black")
