# GPS tracks of immature northern gannets from the Bass Rock

GPS tracks of three immature northern gannets (*Morus bassanus*) tagged
at the Bass Rock, Firth of Forth, in summer 2015. A subset of a larger
dataset, chosen so that the three birds between them span the North Sea
from Shetland to Dutch waters.

## Usage

``` r
gannets
```

## Format

A tibble with 8158 rows and 5 columns:

- id:

  tag identifier, character

- trip:

  foraging trip identifier, character, unique across birds

- datetime_utc:

  time of fix, POSIXct in UTC

- lon:

  longitude in decimal degrees, WGS84

- lat:

  latitude in decimal degrees, WGS84

## Source

Grecian et al. (2018)
[doi:10.1098/rsif.2018.0084](https://doi.org/10.1098/rsif.2018.0084)
