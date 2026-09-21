# meshr

Generate a boundary for a marine region of interest specified by
telemetry data that can then be passed to `inla.mesh.2d`. The size of
the area, complexity of the boundary and projection can be easily
adjusted.

## Usage

``` r
meshr(dat, prj, buff, keep, Neumann = TRUE)
```

## Arguments

- dat:

  a data frame of observations (see details)

- prj:

  a PROJ.4 compatable projection for the region of interest *NOT* WGS84

- buff:

  a buffer to expand region of interest (specified in metres)

- keep:

  the proportion of points to be retained - passed to
  rmapshaper::ms_simplify

- Neumann:

  TRUE - returns a list to allow a Neumann boundary to be implemented  
  FALSE - returns a single object defining the coastline

## Value

a list containing an inla mesh boundary for the region of interest

## Details

It may be useful to specify whether you want a Neumann boundary
condition that either allows or prevents estimation on land:

When Neumann = T the output of the meshr function is a list of spatial
polygons. This list can then be passed to the inla.mesh.2d function and
is ordered so that the Neumann condition is placed on the coastline, and
there are no mesh nodes on land. This could be useful if you wanted to
prevent any estimation on land at all.

When Neumann = F the output of meshr is a single spatial polygon object
containing the area of interest. When this object is then passed to
inla.mesh.2d the Neumann condition is placed on the buffer region not
the coastline. This allows mesh nodes on land to be identified and
passed to the Haakon barrier model.

The telemetry data is given as a dataframe where each row is an observed
location and columns

- 'id':

  individual animal identifier,

- 'date':

  observation time (POSIXct, GMT),

- 'lon':

  observed longitude,

- 'lat':

  observed latitude,

- '...':

  other columns will be ignored

## Examples

``` r
if (FALSE) { # \dontrun{

require(tidyverse)
require(sf)
require(INLA)
require(inlabru)

data(ellie)
prj <- '+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'

b <- meshr(ellie, prj, buff = 5e5, keep = 0.02)

mesh = inla.mesh.2d(boundary = b,
  max.edge = c(250000, 1000000),
  cutoff = 25000,
  max.n = 1000,
  crs = CRS(prj))

ggplot() +
  geom_sf(aes(), data = mapr(ellie, prj, buff = 1e6)) +
  inlabru::gg(mesh) +
  geom_sf(aes(), data = st_as_sf(ellie, coords = c('lon', 'lat')) |>
    st_set_crs('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'))
} # }
```
