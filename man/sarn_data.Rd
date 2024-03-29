% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dataprep.R
\name{sarn_data}
\alias{sarn_data}
\title{Make sarndata object}
\usage{
sarn_data(dem_network, riverMask, dem)
}
\arguments{
\item{dem_network:}{DEM-generated river network (shapefile)}

\item{riverMask:}{River classification raster}

\item{dem:}{Digital elevation model that generated dem_network}
}
\value{
sarndata object
}
\description{
Make a sarndata object to run the actual algorithm on. Checks input data projections and formats too.
}
