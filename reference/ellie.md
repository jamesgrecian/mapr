# Elephant seal Argos satellite data (2 individuals)

Example elephant seal Argos tracking data. Data were sourced from the
Integrated Marine Observing System (IMOS) - IMOS is supported by the
Australian Government through the National Collaborative Research
Infrastructure Strategy and the Super Science Initiative.

## Usage

``` r
ellie
```

## Format

A tibble with 709 rows and 5 columns:

- id:

  individual identifier

- date:

  time of fix, POSIXct in UTC

- lc:

  Argos location class, from most to least accurate: 3, 2, 1, 0, A, B, Z

- lon:

  longitude in decimal degrees, WGS84

- lat:

  latitude in decimal degrees, WGS84
