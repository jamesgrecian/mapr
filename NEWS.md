# mapr 0.2.0

## New features

* New `make_map_furniture()` builds the pieces that turn a projected ggplot
into a finished map: a cookie-cutter mask that hides anything outside the
frame, graticule positions and labels, and plot limits in projected units.

* New `gannets` dataset: GPS tracks of three immature northern gannets from
the Bass Rock, 2015.

* New vignette, `vignette("mapr")`, which builds a map of the gannet tracks
step by step, from a first quick plot to a publication-ready figure.

* `mapr()` gains a `scale` argument to choose the resolution of the Natural
Earth coastline: `"small"`, `"medium"` or `"large"`.

## Breaking changes

* `mapr()` now takes its coastline from `rnaturalearth` rather than
`rworldmap`. The default `scale = "medium"` is more detailed than the old
`rworldmap` coastline; use `scale = "small"` for something closer to the
previous output.

* `mapr()` now projects `sf` input to `prj` when one is supplied. Previously
the CRS of an `sf` object was always used, and `prj` was silently ignored.

## Bug fixes

* `mapr()` works again with `sf` 1.0 and later, which uses spherical geometry
(s2) by default. The function switches s2 off while it runs and restores
your own setting afterwards.

* Invalid coastline polygons are now repaired with `sf::st_make_valid()`
rather than `st_buffer(x, 0)`, which no longer works as a repair under s2.

* `mapr()` gives clearer errors for a missing projection, data without a CRS,
and data frames without `lon` and `lat` columns.

## Other changes

* Now requires R 4.1 and `sf` 1.0 or later. `dplyr` is no longer a
dependency.

* The `ellie` dataset is now fully documented.

## Known issues

* `meshr()` has not yet been updated and fails under `sf`'s default
  spherical geometry. Run `sf::sf_use_s2(FALSE)` before calling it as a
  workaround.

# mapr 0.1.0

* Initial release on GitHub, October 2018, with `mapr()`, `meshr()` and the
  `ellie` example dataset.
