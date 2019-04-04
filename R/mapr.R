##' Generate a land shapefile for a region of interest specified by telemetry
##' data
##'
##' Telemetry data is given either as an sf dataframe, or a tibble where each row
##' is an observed location and columns \describe{ \item{'id'}{individual animal
##' identifier,}\item{'date'}{observation time (POSIXct, GMT),} \item{'lon'}
##' {observed longitude,} \item{'lat'}{observed latitude,} \item{'...'}{other
##' columns will be ignored} }
##'
##' @title mapr
##' @param dat a data frame of observations (see details)
##' @param prj a PROJ.4 compatable projection for the region of interest *NOT*
##'   WGS84. If dat inherits sf this will be scraped from the dataframe
##' @param buff a buffer to expand region of interest (specified in metres) DEFAULT
##' is 1e6 m (1000 km)
##' @return \item{\code{world_shp}}{a projected shapefile for the region of
##' interest taken from Andy South's rworldmap package }
##' @examples
##' \dontrun{
##' require(tidyverse)
##' require(sf)
##' data(ellie)
##' prj <- '+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'
##' world_shp <- mapr(ellie, prj, buff = 1e6)
##'
##' ggplot() +
##'   geom_sf(aes(), data = world_shp) +
##'   geom_sf(aes(), data = st_as_sf(ellie, coords = c('lon', 'lat')) %>%
##'       st_set_crs('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'))
##'}
##' @importFrom dplyr %>%
##' @export
mapr <- function(dat, prj, buff) {

  # Scrape the projection from the dataframe if available
  if(inherits(dat, "sf")){
    prj <- sf::st_crs(dat)
  }
  if(missing(prj)){
    stop("Missing projection")
  }

  # Set default buffer to 1000 km if missing
  if(missing(buff)){
    buff <- 1e6
  }

  # Convert data to sf if required
  # Extract mean latitude to determine hemisphere of study
  if(inherits(dat, "sf")){
    dat_sf <- dat
    mean_lat <- dat_sf %>% sf::st_transform("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") %>% sf::st_coordinates() %>% dplyr::as_tibble() %>% dplyr::summarise(mean(Y))
  }
  else {
    # Convert data to sf. Extract mean lat. Then project
    dat_sf <- sf::st_as_sf(dat, coords = c("lon", "lat")) %>%
      sf::st_set_crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
    mean_lat <- dat_sf %>% sf::st_coordinates() %>% dplyr::as_tibble() %>% dplyr::summarise(mean(Y))
    dat_sf <- dat_sf %>% sf::st_transform(prj)
  }

  # Clip the map to either the Northern or Southern hemisphere
  # if the mean lat is +ve then clip to northern hemisphere if the mean lat is -ve then clip to southern hemisphere
  if (mean_lat > 0) {
    CP <- sf::st_bbox(c(xmin = -180, xmax = 180, ymin = -10, ymax = 90), crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") %>% sf::st_as_sfc()
  } else {
    CP <- sf::st_bbox(c(xmin = -180, xmax = 180, ymin = -84, ymax = 10), crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") %>% sf::st_as_sfc()
  }

  # Load in shapefile from rworldmap, clip to north or south and project
  world_shp <- sf::st_as_sf(rworldmap::countriesLow)
  suppressWarnings(
    world_shp <- sf::st_crop(world_shp, CP)
    )
  world_shp <- sf::st_transform(world_shp, prj) %>% sf::st_buffer(0)

  # Create clip shape for world map based on bounding box and buffer size
  CP <- sf::st_bbox(dat_sf) %>%
    sf::st_as_sfc() %>%
    sf::st_buffer(buff) %>%
    sf::st_segmentize(1000)

  # Load in world shape from rworldmap and clip
  suppressWarnings(
    world_shp <- sf::st_crop(world_shp, CP) %>% sf::st_buffer(0)
  )
  CP <- sf::st_bbox(sf::st_buffer(dat_sf, buff))
  suppressWarnings(
    world_shp <- sf::st_intersection(world_shp, sf::st_as_sfc(CP))
  )

  # Output the shapefile
  return(world_shp)

}
