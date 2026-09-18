#' Build map furniture for a ggplot2 map
#'
#' Returns the pieces that are fiddly to work out by hand, so that you can
#' write the rest of the map as an ordinary `ggplot()` call:
#'
#' \itemize{
#'   \item a **cookie-cutter mask**, a rectangle with your map extent punched
#'     out of it. Drawn in white over the top of your data layers, it hides
#'     anything spilling past the edge of the map and leaves a clean margin.
#'   \item **graticule label positions** along the western and southern edges,
#'     already formatted as `"56\u00b0N"`, `"4\u00b0W"` and so on.
#'   \item **plot limits in projected units**, ready to pass straight to
#'     [ggplot2::coord_sf()].
#' }
#'
#' The bounding box is densified in geographic coordinates before projection,
#' so the edges of the map follow curved graticules rather than straight lines
#' in the target projection. Over a wide extent this is obvious; over the North
#' Sea it is slight but harmless.
#'
#' See the examples below for a complete map, and `help("projections")` if
#' coordinate reference systems are new to you.
#'
#' @param xmin,xmax,ymin,ymax Numeric. Map extent in WGS84 decimal degrees.
#'   `xmin` must be less than `xmax`; boxes crossing the antimeridian are not
#'   supported.
#' @param crs Target coordinate reference system, passed to
#'   [sf::st_transform()]. Assumed to be projected with metres as its unit.
#'   See `help("projections")` for choosing one.
#' @param buffer Numeric. Margin around the extent on all sides, in CRS units.
#'   This is the white space the graticule labels are written into. Defaults to
#'   500000 (500 km), which suits flyway-scale maps; for a North Sea extent try
#'   25000 to 50000, and for a single colony a few thousand.
#' @param lat_by,lon_by Numeric. Spacing of parallel and meridian labels in
#'   degrees. Label positions snap to multiples of these values falling inside
#'   the extent, so `lat_by = 2` on a 51 to 62 degree extent labels 52, 54, 56,
#'   58, 60 and 62.
#' @param densify Numeric. Maximum segment length in **degrees** used when
#'   densifying the bounding box, passed to [sf::st_segmentize()]. Smaller
#'   values give smoother curved edges at the cost of more vertices.
#'
#' @return A named list with components:
#' \describe{
#'   \item{flyway_wgs84}{`sfc` polygon of the densified extent in EPSG:4326.}
#'   \item{flyway}{The same polygon transformed to `crs`. Draw it with
#'     `fill = NA` for a border around the map.}
#'   \item{cookie}{`sfc` polygon covering the buffered extent with the map
#'     extent punched out. Draw it filled white, after your data layers and
#'     before the labels.}
#'   \item{parallels}{`sf` points along the western edge, with columns `lat`,
#'     `lon` and `label`.}
#'   \item{meridians}{`sf` points along the southern edge, with columns `lat`,
#'     `lon` and `label`.}
#'   \item{xlim, ylim}{Length-2 numeric vectors in CRS units, for
#'     [ggplot2::coord_sf()].}
#' }
#'
#' @examples
#' # A Lambert azimuthal equal-area projection centred on the North Sea.
#' # Equal-area is the safe default when areas and overlaps matter.
#' laea <- "+proj=laea +lat_0=56 +lon_0=2 +datum=WGS84 +units=m"
#'
#' mf <- make_map_furniture(
#'   xmin = -6, xmax = 9, ymin = 51, ymax = 62,
#'   crs = laea,
#'   buffer = 30000,   # 30 km margin for the labels
#'   lat_by = 2,       # label every 2 degrees of latitude
#'   lon_by = 4        # and every 4 of longitude
#' )
#'
#' # Plot limits, in metres, because the projection is in metres
#' mf$xlim
#'
#' # The labels it worked out for you
#' mf$parallels$label
#' mf$meridians$label
#'
#' \dontrun{
#' # ---------------------------------------------------------------------
#' # A complete map. Land from Natural Earth, your own tracks and wind farms.
#' # ---------------------------------------------------------------------
#' library(sf)
#' library(ggplot2)
#'
#' # 1. Coastline. Crop in lon/lat first, then project: cropping a whole-world
#' #    layer after projecting is slow and can throw geometry errors.
#' land <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
#' land <- st_crop(land, c(xmin = -12, ymin = 48, xmax = 16, ymax = 66))
#' land <- st_transform(land, laea)
#'
#' # 2. Your data. Longitude goes first in coords, and you must say which CRS
#' #    the numbers are in: GPS and Argos data is almost always EPSG:4326.
#' d <- read.csv("tracks.csv")
#' tracks <- st_as_sf(d, coords = c("lon", "lat"), crs = 4326)
#'
#' # A shapefile or geopackage carries its own CRS, so just read it
#' windfarms <- st_read("windfarms.shp")
#'
#' # Note there is no st_transform() on these two. coord_sf() reprojects every
#' # layer on the fly, so layers in different CRSs still line up. You only need
#' # to transform by hand when you are measuring something.
#'
#' # 3. Draw it. Layer order matters: data, then the mask, then the labels.
#' ggplot() +
#'   geom_sf(data = land, fill = "grey90", colour = "grey50", linewidth = 0.2) +
#'   geom_sf(data = windfarms, fill = "steelblue", colour = NA, alpha = 0.6) +
#'   geom_sf(data = tracks, aes(colour = id), linewidth = 0.3, show.legend = FALSE) +
#'   geom_sf(data = mf$cookie, fill = "white", colour = NA) +
#'   geom_sf(data = mf$flyway, fill = NA, colour = "black", linewidth = 0.3) +
#'   geom_sf_text(data = mf$parallels, aes(label = label), hjust = 1.3, size = 3) +
#'   geom_sf_text(data = mf$meridians, aes(label = label), vjust = 1.8, size = 3) +
#'   coord_sf(xlim = mf$xlim, ylim = mf$ylim, crs = laea, expand = FALSE) +
#'   theme_bw() +
#'   theme(
#'     axis.title = element_blank(),
#'     axis.text = element_blank(),
#'     axis.ticks = element_blank(),
#'     panel.border = element_blank(),
#'     panel.grid = element_line(colour = "grey85", linewidth = 0.2)
#'   )
#'
#' # Things to try from here:
#' #   - move the colony marker on with another geom_sf()
#' #   - facet by year with facet_wrap(~ year)
#' #   - swap laea for "+proj=laea +lat_0=58 +lon_0=-3 ..." to centre on Moray
#' #   - ggsave("map.png", width = 7, height = 8, dpi = 300)
#' }
#'
#' @export
make_map_furniture <- function(xmin, xmax, ymin, ymax,
                               crs,
                               buffer = 500000,
                               lat_by = 10,
                               lon_by = 20,
                               densify = 1) {

  if (xmin >= xmax) {
    stop("`xmin` must be less than `xmax`; antimeridian-crossing boxes are not supported.",
         call. = FALSE)
  }
  if (ymin >= ymax) {
    stop("`ymin` must be less than `ymax`.", call. = FALSE)
  }
  if (ymin < -90 || ymax > 90) {
    stop("`ymin` and `ymax` must lie within [-90, 90].", call. = FALSE)
  }
  if (missing(crs)) {
    stop("`crs` must be supplied. See help(\"projections\") for choosing one.",
         call. = FALSE)
  }

  # Densify before setting the CRS: with no CRS attached, st_segmentize()
  # treats `densify` as degrees. Setting the CRS first would switch it to
  # metres and densify into millions of vertices.
  flyway_wgs84 <- sf::st_bbox(c(xmin = xmin, xmax = xmax,
                                ymin = ymin, ymax = ymax))
  flyway_wgs84 <- sf::st_as_sfc(flyway_wgs84)
  flyway_wgs84 <- sf::st_segmentize(flyway_wgs84, densify)
  flyway_wgs84 <- sf::st_set_crs(flyway_wgs84, 4326)

  flyway <- sf::st_transform(flyway_wgs84, crs)

  # Buffered extent in projected space
  fb   <- sf::st_bbox(flyway)
  xlim <- unname(c(fb[["xmin"]] - buffer, fb[["xmax"]] + buffer))
  ylim <- unname(c(fb[["ymin"]] - buffer, fb[["ymax"]] + buffer))

  encl <- list(cbind(
    c(xlim[1], xlim[2], xlim[2], xlim[1], xlim[1]),
    c(ylim[1], ylim[1], ylim[2], ylim[2], ylim[1])
  ))
  encl <- sf::st_sfc(sf::st_polygon(encl), crs = crs)

  cookie <- sf::st_difference(encl, flyway)

  # Parallel labels along the western edge
  lat_seq <- seq(ceiling(ymin / lat_by) * lat_by,
                 floor(ymax / lat_by) * lat_by,
                 by = lat_by)
  parallels <- data.frame(lat = lat_seq, lon = xmin)
  parallels$label <- format_degrees(parallels$lat, "NS")
  parallels <- sf::st_as_sf(parallels, coords = c("lon", "lat"),
                            crs = 4326, remove = FALSE)
  parallels <- sf::st_transform(parallels, crs)

  # Meridian labels along the southern edge
  lon_seq <- seq(ceiling(xmin / lon_by) * lon_by,
                 floor(xmax / lon_by) * lon_by,
                 by = lon_by)
  meridians <- data.frame(lat = ymin, lon = lon_seq)
  meridians$label <- format_degrees(meridians$lon, "EW")
  meridians <- sf::st_as_sf(meridians, coords = c("lon", "lat"),
                            crs = 4326, remove = FALSE)
  meridians <- sf::st_transform(meridians, crs)

  list(flyway_wgs84 = flyway_wgs84,
       flyway       = flyway,
       cookie       = cookie,
       parallels    = parallels,
       meridians    = meridians,
       xlim         = xlim,
       ylim         = ylim)
}


#' Format degree values as graticule labels
#'
#' @param x Numeric vector of degrees.
#' @param hemispheres Either `"NS"` for latitudes or `"EW"` for longitudes.
#'
#' @return A character vector, e.g. `c("40\u00b0S", "0\u00b0", "40\u00b0N")`.
#'
#' @noRd
format_degrees <- function(x, hemispheres = c("NS", "EW")) {
  hemispheres <- match.arg(hemispheres)
  suffix <- if (hemispheres == "NS") c("S", "N") else c("W", "E")

  out <- paste0(abs(x), "\u00b0", ifelse(x < 0, suffix[1], suffix[2]))
  out[x == 0] <- "0\u00b0"
  out
}
