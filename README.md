<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

mapr
====

**mapr** is an R package that makes it easier to make maps in R

Given a set of locations, for example from a tagged marine animal, the `mapr` function will load a global shapefile from the Natural Earth database using `rworldmap` and manipulate it for plotting using `ggplot2` and `sf`

Alternatively, given the same set of locations the `meshr` function will help you to create a shapefile (or nested list of shapefiles) that can be used as a boundary when creating an `INLA` mesh using `inla.mesh.2d`

Installation
------------

To download the current development version from GitHub:

``` r
# install.packages("devtools")  
devtools::install_github("jamesgrecian/mapr")
#> purrr (0.2.5 -> 0.3.0) [CRAN]
#> 
#> The downloaded binary packages are in
#>  /var/folders/ys/0d44zxtj55j_kmscgvwr74rw0000gn/T//RtmpwKWfWj/downloaded_packages
#>   
   checking for file ‘/private/var/folders/ys/0d44zxtj55j_kmscgvwr74rw0000gn/T/RtmpwKWfWj/remotes1f297086314e/jamesgrecian-mapr-994bdf7/DESCRIPTION’ ...
  
✔  checking for file ‘/private/var/folders/ys/0d44zxtj55j_kmscgvwr74rw0000gn/T/RtmpwKWfWj/remotes1f297086314e/jamesgrecian-mapr-994bdf7/DESCRIPTION’
#> 
  
─  preparing ‘mapr’:
#> 
  
   checking DESCRIPTION meta-information ...
  
✔  checking DESCRIPTION meta-information
#> 
  
─  checking for LF line-endings in source and make files and shell scripts
#> 
  
─  checking for empty or unneeded directories
#> ─  looking to see if a ‘data/datalist’ file should be added
#> 
  
   
#> 
  
─  building ‘mapr_0.1.0.tar.gz’
#> 
```

### An example map

Here's an example of how to generate a map containing a coastline and some animal locations using the `mapr` function alongside the `sf` and `ggplot2` libraries

``` r
# load libraries
require(tidyverse)
require(sf)
require(mapr)

# load example dataset
data(ellie)

# define an appropriate proj.4 projection
prj <- '+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'

# use mapr to generate a shapefile
world_shp <- mapr(ellie, prj, buff = 1e6)

# output a plot using ggplot
p1 <- ggplot() +
  geom_sf(aes(), data = world_shp) +
  geom_sf(aes(), data = st_as_sf(ellie, coords = c('lon', 'lat'))
          %>% st_set_crs('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'))

print(p1)
```

![](README-mapr%20example%20with%20ellies-1.png)

An example INLA mesh
--------------------

When using INLA to analyse animal movement data it is useful to base the mesh on the distribution of locations.

Here's an example of how to generate a boundary shapefile using `meshr` that can then be passed to `inla.mesh.2d`, we can plot the mesh using `sf` and `ggplot2`

``` r
# load libraries
require(tidyverse)
require(sf)
require(mapr)
require(INLA)
require(inlabru)

# load example dataset
data(ellie)

# define an appropriate proj.4 projection
prj <- '+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'

# use meshr to generate the boundary
b <- meshr(ellie, prj, buff = 5e5, keep = 0.05, Neumann = T)

# use the boundary to generate the INLA mesh
mesh = inla.mesh.2d(boundary = b, max.edge = c(250000, 1e+06), cutoff = 25000, max.n = 500)

# output a plot using ggplot
p2 <- ggplot() + 
  geom_sf(aes(), data = mapr(ellie, prj, buff = 1e6)) +
  inlabru::gg(mesh) +
  geom_sf(aes(), data = st_as_sf(ellie, coords = c("lon", "lat"))
          %>% st_set_crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))

print(p2)
```

![](README-meshr%20example%20with%20ellies-1.png)
