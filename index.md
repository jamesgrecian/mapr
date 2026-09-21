# mapr

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

**mapr** makes it easier to produce clean, projected maps in R. Given a
set of locations, for example from a tagged marine animal,
[`mapr()`](https://jamesgrecian.github.io/mapr/reference/mapr.md)
fetches a coastline from the Natural Earth database, crops it to your
study area and projects it, ready for plotting with `ggplot2` and `sf`.
[`make_map_furniture()`](https://jamesgrecian.github.io/mapr/reference/make_map_furniture.md)
then adds a proper frame and graticule labels to turn the plot into a
finished map.

## Installation

Install the development version from GitHub:

``` r

# install.packages("remotes")
remotes::install_github("jamesgrecian/mapr", build_vignettes = TRUE)
```

## Getting started

The guide walks through building a publication-ready map of seabird
tracks, step by step:

``` r

vignette("mapr")
```
