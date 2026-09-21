#' Build map furniture for a ggplot2 map
#'
#' Returns the pieces that are fiddly to work out by hand, so that you can
#' write the rest of the map as an ordinary `ggplot()` call:
#'
#' \itemize{
#'   \item a **cookie-cutter mask**, a rectangle with your map extent punched
#'     out of it. Drawn in white over the top of your data layers, it hides
#'     anything spilling past the edge of the map and leaves a clean margin.
#'   \item **graticule positions and labels** along the western and southern
#'     edges, already formatted as `"55\u00b0N"`, `"5\u00b0W"` and so on.
#'   \item **plot limits in projected units**, ready to pass straight to
#'     [ggplot2::coord_sf()].
#' }
#'
#' The bounding box is densified in geographic coordinates before projection,
#' so the edges of the map follow the curved graticules rather than straight
#' lines in the target projection.
#'
#' Use it alongside [mapr()], which supplies the land. The land needs to reach
#' past the frame on every side, since the cookie hides anything beyond it.
#' See `vignette("mapr")` for a step-by-step guide to building a map.
#'
#' @param xmin,xmax,ymin,ymax Numeric. Map extent in WGS84 decimal degrees.
#'   `xmin` must be less than `xmax`; boxes crossing the antimeridian are not
#'   supported.
#' @param crs Target projection, as anything [sf::st_transform()] accepts: an
#'   EPSG code or a PROJ string. Should be projected, with metres as its unit,
#'   and the same projection you use for [mapr()] and [ggplot2::coord_sf()].
#' @param buffer Numeric. Margin around the frame on all sides, in metres. This
#'   is the white space the graticule labels are written into, so it needs to
#'   be wide enough to hold them. Defaults to 500000 (500 km), which suits an
#'   ocean basin; for a North Sea map around 200000 works well.
#' @param lat_by,lon_by Numeric. Spacing of the graticules and their labels in
#'   degrees. Positions snap to multiples of these values falling inside the
#'   extent, so `lat_by = 5` on a 50 to 62 degree extent gives 50, 55 and 60.
#' @param densify Numeric. Maximum segment length in **degrees** used when
#'   densifying the bounding box, passed to [sf::st_segmentize()]. Smaller
#'   values give smoother curved edges at the cost of more vertices.
#'
#' @return A named list with components:
#' \describe{
#'   \item{flyway_wgs84}{`sfc` polygon of the densified frame in EPSG:4326.}
#'   \item{flyway}{The same polygon transformed to `crs`. Draw it with
#'     `fill = NA` for a border around the map.}
#'   \item{cookie}{`sfc` polygon covering the buffered frame with the map
#'     extent punched out. Draw it filled white, after your data layers and
#'     before the labels.}
#'   \item{parallels}{`sf` points along the western edge, with columns `lat`,
#'     `lon` and `label`. Pass `lat` to [ggplot2::scale_y_continuous()] as
#'     `breaks` to draw matching graticules.}
#'   \item{meridians}{`sf` points along the southern edge, with columns `lat`,
#'     `lon` and `label`. Pass `lon` to [ggplot2::scale_x_continuous()] as
#'     `breaks` to draw matching graticules.}
#'   \item{xlim, ylim}{Length-2 numeric vectors in CRS units, for
#'     [ggplot2::coord_sf()].}
#' }
#'
#' @examples
#' prj <- "+proj=utm +zone=30 +datum=WGS84 +units=m +no_defs"
#'
#' mf <- make_map_furniture(
#'   xmin = -7.5, xmax = 10, ymin = 50, ymax = 62,
#'   crs = prj,
#'   buffer = 200000,
#'   lat_by = 5,
#'   lon_by = 5
#' )
#'
#' # Plot limits, in metres, because the projection is in metres
#' mf$xlim
#'
#' # The graticule labels
#' mf$parallels$label
#' mf$meridians$label
#'
#' \donttest{
#' library(sf)
#' library(ggplot2)
#'
#' data(gannets)
#' gannets_sf <- st_as_sf(gannets, coords = c("lon", "lat"), crs = 4326)
#' land <- mapr(gannets, prj, buff = 400000)
#'
#' # Layer order matters: land and data, then the cookie, then the frame,
#' # then the labels
#' ggplot() +
#'   theme_minimal(base_size = 8) +
#'   geom_sf(data = land, fill = "grey85", colour = "grey60", linewidth = 0.2) +
#'   geom_sf(data = gannets_sf, aes(colour = id), size = 0.1,
#'           show.legend = FALSE) +
#'   geom_sf(data = mf$cookie, fill = "white", colour = NA) +
#'   geom_sf(data = mf$flyway, fill = NA, linewidth = 0.3) +
#'   scale_x_continuous(breaks = mf$meridians$lon) +
#'   scale_y_continuous(breaks = mf$parallels$lat) +
#'   coord_sf(xlim = mf$xlim, ylim = mf$ylim, crs = prj, expand = FALSE) +
#'   theme(axis.text = element_blank(),
#'         axis.title = element_blank()) +
#'   geom_sf_text(data = mf$parallels, aes(label = label),
#'                size = 2.5, colour = "grey40",
#'                nudge_x = -15000, hjust = 1) +
#'   geom_sf_text(data = mf$meridians, aes(label = label),
#'                size = 2.5, colour = "grey40",
#'                nudge_y = -15000, vjust = 1)
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
    stop("`crs` must be supplied: a projected CRS, such as an EPSG code or PROJ string.",
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
