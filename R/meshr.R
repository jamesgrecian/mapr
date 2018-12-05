##' Generate an inla mesh nested boundary for a region of interest
##' specified by telemetry data
##'
##' The telemetry data is given as a dataframe where each row is an observed
##' location and columns \describe{ \item{'id'}{individual animal identifier,}
##' \item{'date'}{observation time (POSIXct, GMT),} \item{'lon'}{observed
##' longitude,} \item{'lat'}{observed latitude,} \item{'...'}{other columns
##' will be ignored} }
##'
##' @title meshr
##' @param dat a data frame of observations (see details)
##' @param prj a PROJ.4 compatable projection for the region of interest *NOT*
##'   WGS84
##' @param buff a buffer to expand region of interest specified in metres
##' @param keep the proportion of points to be retained - passed to rmapshaper::ms_simplify
##' @param Neumann TRUE - returns a list to allow a Neumann boundary to be implemented \cr
##' FALSE - returns a single object defining the coastline
##' @return a list containing an inla mesh boundary for the region of interest
##' @examples
##' \dontrun{
##'
##' require(tidyverse)
##' require(sf)
##' require(INLA)
##' require(inlabru)
##'
##' data(ellie)
##' prj <- '+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'
##'
##' b <- meshr(ellie, prj, buff = 5e5, keep = 0.02)
##'
##' mesh = inla.mesh.2d(boundary = b, max.edge = c(250000, 1000000), cutoff = 25000, max.n = 1000)
##'
##' ggplot() +
##'   geom_sf(aes(), data = mapr(ellie, prj, buff = 1e6)) +
##'   inlabru::gg(mesh) +
##'   geom_sf(aes(), data = st_as_sf(ellie, coords = c('lon', 'lat')) %>%
##'     st_set_crs('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'))
##' }
##' @importFrom dplyr %>%
##' @export
meshr <- function(dat, prj, buff, keep, Neumann = T) {

    # if the mean lat is +ve then clip to northern hemisphere if the mean lat is -ve then clip to southern hemisphere
    if (mean(dat$lat) > 0) {
        CP <- sf::st_bbox(c(xmin = -180, xmax = 180, ymin = -10, ymax = 90), crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") %>% sf::st_as_sfc()
    } else {
        CP <- sf::st_bbox(c(xmin = -180, xmax = 180, ymin = -90, ymax = 10), crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") %>% sf::st_as_sfc()
    }

    # load in shapefile from rworldmap, clip to north or south and project
    world_shp <- sf::st_as_sf(rworldmap::countriesLow)
    world_shp <- sf::st_crop(world_shp, CP)
    world_shp <- sf::st_transform(world_shp, prj) %>% sf::st_buffer(0)

    # convert data to sf and project
    dat_sf <- sf::st_as_sf(dat, coords = c("lon", "lat")) %>% sf::st_set_crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") %>% sf::st_transform(prj)

    # create area of interest from convex hull around data with buffer
    sf_poly <- sf::st_convex_hull(sf::st_union(dat_sf)) %>% sf::st_buffer(buff)

    # create padding area for inla mesh
    sf_poly_buff <- sf_poly %>% sf::st_buffer(buff)

    # crop world shape to area of interest
    world_shp <- sf::st_intersection(world_shp, sf_poly_buff)

    # create internal mesh area from world shapefile
    world_shp <- sf::st_sym_difference(sf::st_union(world_shp), sf_poly_buff)

    # simplify internal mesh area using ms_simplify
    world_shp = rmapshaper::ms_simplify(world_shp, keep = keep)

    # output
    if (Neumann == T) {
      return(list(sf::as_Spatial(sf_poly), list(sf::as_Spatial(sf_poly_buff), sf::as_Spatial(world_shp))))
    } else {
      return(sf::as_Spatial(world_shp))
    }

}
