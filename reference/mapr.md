# mapr

Generate a land shapefile for a region of interest specified by
telemetry data

## Usage

``` r
mapr(dat, prj, buff = 1e+06, scale = c("medium", "small", "large"))
```

## Arguments

- dat:

  an `sf` object, or a data frame with `lon` and `lat` columns (see
  details)

- prj:

  a projection for the region of interest, as anything
  [`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html)
  accepts: an EPSG code, a WKT string or a PROJ string. Should be
  projected, *NOT* WGS84. If `dat` inherits `sf` and `prj` is missing,
  the CRS of `dat` is used instead.

- buff:

  a buffer expanding the region of interest beyond the locations
  themselves, in metres. Defaults to 1e6 (1000 km).

- scale:

  resolution of the Natural Earth coastline, one of `"medium"` (1:50m,
  the default), `"small"` (1:110m) or `"large"` (1:10m). The `"large"`
  scale needs the separate `rnaturalearthhires` data package, which is
  not on CRAN:
  `install.packages("rnaturalearthhires", repos = "https://ropensci.r-universe.dev")`

## Value

an `sf` object of land polygons, cropped to the buffered extent of `dat`
and projected to `prj`.

## Details

Telemetry data is given either as an `sf` object, or as a data frame
where each row is an observed location, with columns

- `lon`:

  observed longitude in decimal degrees,

- `lat`:

  observed latitude in decimal degrees,

- `...`:

  other columns are ignored

Land polygons come from the Natural Earth database via
[`rnaturalearth::ne_countries()`](https://docs.ropensci.org/rnaturalearth/reference/ne_countries.html).
Choose `scale` to suit the extent you are mapping: `"small"` is adequate
for an ocean basin and visibly blocky over a coastline, `"large"` is
unnecessarily detailed for anything wider than a few hundred kilometres
and slow to draw.

The map is clipped to one hemisphere before projecting, chosen from the
mean latitude of `dat`, since a projection suited to one pole distorts
the other beyond use. Data straddling the equator will therefore lose
part of the opposite hemisphere.

## Examples

``` r
data(ellie)

prj <- "+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m"
world_shp <- mapr(ellie, prj, buff = 1e6)
#> although coordinates are longitude/latitude, st_intersection assumes that they
#> are planar

if (FALSE) { # \dontrun{
library(sf)
library(ggplot2)

ellie_sf <- st_as_sf(ellie, coords = c("lon", "lat"), crs = 4326)

ggplot() +
  geom_sf(data = world_shp) +
  geom_sf(data = ellie_sf, size = 0.4)
} # }
```
