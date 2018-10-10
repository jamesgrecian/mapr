<!-- README.md is generated from README.Rmd. Please edit that file -->
mapr
====

mapr is an R package that makes it easier to make maps in R.

Given a set of locations, for example from a tagged animal, mapr will load a global shapefile from the Natural Earth database using rworldmap and manipulate it for plotting using ggplot2.

Installation
------------

To download the current development version from GitHub:

``` r
# install.packages("devtools")  
devtools::install_github("jamesgrecian/mapr")
```

Example
-------

Here's a quick example of how to generate a plot

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

![](README-example-1.png)
