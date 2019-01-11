<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

mapr
====

mapr is an R package that makes it easier to make maps in R.

Given a set of locations, for example from a tagged animal, mapr will load a global shapefile from the Natural Earth database using rworldmap and manipulate it for plotting using ggplot2 and use in INLA.

Installation
------------

To download the current development version from GitHub:

``` r
# install.packages("devtools")  
devtools::install_github("jamesgrecian/mapr")
```

Example 1
---------

Here's a quick example of how to generate a plot using the 'mapr' function

``` r
#load libraries
require(tidyverse)
require(sf)
require(mapr)

#load example dataset
data(ellie)

#define an appropriate proj.4 projection
prj <- '+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'

#use mapr to generate a shapefile
world_shp <- mapr(ellie, prj, buff = 1e6)

#output a plot using ggplot
p1 <- ggplot() +
  geom_sf(aes(), data = world_shp) +
  geom_sf(aes(), data = st_as_sf(ellie, coords = c('lon', 'lat')) %>% st_set_crs('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'))

print(p1)
```

![](README-mapr%20example%20with%20ellies-1.png)

Example 2
---------

Here's a quick example of how to generate an inla mesh using the meshr function

``` r
#load libraries
require(tidyverse)
require(sf)
require(mapr)
require(INLA)
require(inlabru)

#load example dataset
data(ellie)

#define an appropriate proj.4 projection
prj <- '+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'

#use meshr to generate the boundary
b <- meshr(ellie, prj, buff = 5e5, keep = 0.05, Neumann = T)

#use the meshr boundary to generate the INLA mesh
mesh = inla.mesh.2d(boundary = b, max.edge = c(250000, 1e+06), cutoff = 25000, max.n = 1000)

#output a plot using ggplot
p2 <- ggplot() + 
  geom_sf(aes(), data = mapr(ellie, prj, buff = 1e6)) +
  inlabru::gg(mesh) +
  geom_sf(aes(), data = st_as_sf(ellie, coords = c("lon", "lat")) %>% st_set_crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))

print(p2)
```

![](README-meshr%20example%20with%20ellies-1.png)
