% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dataprep.R
\name{checkProj}
\alias{checkProj}
\title{Check input data projection}
\usage{
checkProj(dem_network, rs_raster, dem_full)
}
\arguments{
\item{dem_network:}{vector dem river network to be used in SARNr}

\item{rs_raster:}{raster water mask to be used in SARNr}

\item{dem_full:}{raster dem to be used in SARNr}
}
\description{
Ensures raster and vector input data are all in the same projection
}
