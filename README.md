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
#> Downloading GitHub repo jamesgrecian/mapr@master
#> from URL https://api.github.com/repos/jamesgrecian/mapr/zipball/master
#> Installing mapr
#> '/Library/Frameworks/R.framework/Resources/bin/R' --no-site-file  \
#>   --no-environ --no-save --no-restore --quiet CMD INSTALL  \
#>   '/private/var/folders/ys/0d44zxtj55j_kmscgvwr74rw0000gn/T/RtmpzX45pm/devtools5fdd5d64f71b/jamesgrecian-mapr-ad1f027'  \
#>   --library='/Users/jamesgrecian/Library/R/3.4/library' --install-tests
#> 
```

Example
-------

Here's a quick example of how to generate a plot

``` r
#load libraries
require(tidyverse)
#> Loading required package: tidyverse
#> ── Attaching packages ────────────────────────────────── tidyverse 1.2.1 ──
#> ✔ ggplot2 3.0.0.9000     ✔ purrr   0.2.5     
#> ✔ tibble  1.4.2          ✔ dplyr   0.7.6     
#> ✔ tidyr   0.8.1          ✔ stringr 1.3.1     
#> ✔ readr   1.1.1          ✔ forcats 0.3.0
#> Warning: package 'tidyr' was built under R version 3.4.4
#> Warning: package 'purrr' was built under R version 3.4.4
#> Warning: package 'dplyr' was built under R version 3.4.4
#> Warning: package 'stringr' was built under R version 3.4.4
#> ── Conflicts ───────────────────────────────────── tidyverse_conflicts() ──
#> ✖ dplyr::filter() masks stats::filter()
#> ✖ dplyr::lag()    masks stats::lag()
require(sf)
#> Loading required package: sf
#> Warning: package 'sf' was built under R version 3.4.4
#> Linking to GEOS 3.6.1, GDAL 2.1.3, proj.4 4.9.3
require(mapr)
#> Loading required package: mapr

#load example dataset
data(ellie)

#define an appropriate proj.4 projection
prj <- '+proj=laea +lat_0=-60 +lon_0=70 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'

#use mapr to generate a shapefile
world_shp <- mapr(ellie, prj, buff = 1e6)
#> although coordinates are longitude/latitude, st_intersection assumes that they are planar
#> Warning: attribute variables are assumed to be spatially constant
#> throughout all geometries
#> Warning: attribute variables are assumed to be spatially constant
#> throughout all geometries

#output a plot using ggplot
ggplot() +
  geom_sf(aes(), data = world_shp) +
  geom_sf(aes(), data = st_as_sf(ellie, coords = c('lon', 'lat')) %>% st_set_crs('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'))
```

![](README-example-1.png)
