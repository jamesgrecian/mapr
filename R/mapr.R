##' Generate a land shapefile for a region of interest specified by telemetry
##' data
##'
##' Telemetry data is given either as an `sf` object, or as a data frame where
##' each row is an observed location, with columns \describe{
##'   \item{`lon`}{observed longitude in decimal degrees,}
##'   \item{`lat`}{observed latitude in decimal degrees,}
##'   \item{`...`}{other columns are ignored} }
##'
##' Land polygons come from the Natural Earth database via
##' [rnaturalearth::ne_countries()]. Choose `scale` to suit the extent you are
##' mapping: `"small"` is adequate for an ocean basin and visibly blocky over a
##' coastline, `"large"` is unnecessarily detailed for anything wider than a
##' few hundred kilometres and slow to draw.
##'
##' The map is clipped to one hemisphere before projecting, chosen from the
##' mean latitude of `dat`, since a projection suited to one pole distorts the
##' other beyond use. Data straddling the equator will therefore lose part of
##' the opposite hemisphere.
##'
##' @title mapr
##' @param dat an `sf` object, or a data frame with `lon` and `lat` columns
##'   (see details)
##' @param prj a projection for the region of interest, as anything
##'   [sf::st_crs()] accepts: an EPSG code, a WKT string or a PROJ string.
##'   Should be projected, *NOT* WGS84. If `dat` inherits `sf` and `prj` is
##'   missing, the CRS of `dat` is used instead.
##' @param buff a buffer expanding the region of interest beyond the locations
##'   themselves, in metres. Defaults to 1e6 (1000 km).
##' @param scale resolution of the Natural Earth coastline, one of `"medium"`
##'   (1:50m, the default), `"small"` (1:110m) or `"large"` (1:10m). The
##'   `"large"` scale needs the separate `rnaturalearthhires` data package,
##'   which is not on CRAN:
##'   `install.packages("rnaturalearthhires", repos = "https://ropensci.r-universe.dev")`
##' @return an `sf` object of land polygons, cropped to the buffered extent of
##'   `dat` and projected to `prj`.
##' @examples
##' data(ellie)
##'
##' prj <- "+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m"
##' world_shp <- mapr(ellie, prj, buff = 1e6)
##'
##' \dontrun{
##' library(sf)
##' library(ggplot2)
##'
##' ellie_sf <- st_as_sf(ellie, coords = c("lon", "lat"), crs = 4326)
##'
##' ggplot() +
##'   geom_sf(data = world_shp) +
##'   geom_sf(data = ellie_sf, size = 0.4)
##' }
##' @export
mapr <- function(dat, prj, buff = 1e6, scale = c("medium", "small", "large")) {

  scale <- match.arg(scale)

  # This function was written for planar geometry on lon/lat data, which is
  # what sf used before version 1.0. Switch the s2 spherical engine off for
  # the duration, and put the user's own setting back when the function
  # exits, whether it succeeds or fails.
  old_s2 <- suppressMessages(sf::sf_use_s2(FALSE))
  on.exit(suppressMessages(sf::sf_use_s2(old_s2)), add = TRUE)

  if (scale == "large" && !requireNamespace("rnaturalearthhires", quietly = TRUE)) {
    stop("scale = \"large\" needs the rnaturalearthhires package:\n",
         "  install.packages(\"rnaturalearthhires\", ",
         "repos = \"https://ropensci.r-universe.dev\")",
         call. = FALSE)
  }

  # Projection: use the one supplied, or fall back to the CRS of an sf input.
  # Note this differs from earlier versions, which always took the CRS from an
  # sf object and so silently ignored a projection the user had asked for.
  if (missing(prj)) {
    if (inherits(dat, "sf")) {
      prj <- sf::st_crs(dat)
    } else {
      stop("Missing projection.", call. = FALSE)
    }
  }
  if (is.na(sf::st_crs(prj))) {
    stop("`prj` is not a coordinate reference system sf recognises.",
         call. = FALSE)
  }

  # Coerce to sf, in WGS84, so the hemisphere test is always in degrees
  if (inherits(dat, "sf")) {
    if (is.na(sf::st_crs(dat))) {
      stop("`dat` has no coordinate reference system. If the coordinates are ",
           "longitude and latitude, set it with sf::st_crs(dat) <- 4326.",
           call. = FALSE)
    }
    dat_sf <- dat
  } else {
    if (!all(c("lon", "lat") %in% names(dat))) {
      stop("`dat` must be an sf object, or have columns named `lon` and `lat`.",
           call. = FALSE)
    }
    dat_sf <- sf::st_as_sf(dat, coords = c("lon", "lat"), crs = 4326)
  }

  mean_lat <- mean(sf::st_coordinates(sf::st_transform(dat_sf, 4326))[, "Y"])

  dat_sf <- sf::st_transform(dat_sf, prj)

  # Clip the world to the hemisphere the animals are in, with a little overlap
  # across the equator
  if (mean_lat > 0) {
    hemisphere <- c(xmin = -180, xmax = 180, ymin = -10, ymax = 90)
  } else {
    hemisphere <- c(xmin = -180, xmax = 180, ymin = -84, ymax = 10)
  }
  hemisphere <- sf::st_as_sfc(sf::st_bbox(hemisphere, crs = 4326))

  world_shp <- rnaturalearth::ne_countries(scale = scale, returnclass = "sf")

  # Declaring attributes constant stops st_crop() and st_intersection()
  # warning that they are "assumed to be spatially constant", without
  # suppressing any other warning.
  sf::st_agr(world_shp) <- "constant"

  # Crop to the hemisphere in lon/lat, then project
  world_shp <- sf::st_make_valid(world_shp)
  world_shp <- sf::st_crop(world_shp, hemisphere)

  world_shp <- sf::st_make_valid(sf::st_transform(world_shp, prj))
  sf::st_agr(world_shp) <- "constant"

  # Region of interest: the extent of the locations, buffered. Segmentized so
  # that the edges stay curved when the polygon is drawn in a projection.
  roi <- sf::st_buffer(sf::st_as_sfc(sf::st_bbox(dat_sf)), buff)
  roi <- sf::st_segmentize(roi, 1000)

  world_shp <- sf::st_make_valid(sf::st_crop(world_shp, roi))
  sf::st_agr(world_shp) <- "constant"

  # Square off the rounded corners left by the buffer
  box <- sf::st_as_sfc(sf::st_bbox(sf::st_buffer(dat_sf, buff)))
  world_shp <- sf::st_intersection(world_shp, box)

  world_shp
}
