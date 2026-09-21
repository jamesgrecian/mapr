##' Elephant seal Argos satellite data (2 individuals)
##'
##' Example elephant seal Argos tracking data. Data were sourced from
##' the Integrated Marine Observing System (IMOS) - IMOS is supported by the
##' Australian Government through the National Collaborative Research Infrastructure
##' Strategy and the Super Science Initiative.
##'
##' @format A tibble with 709 rows and 5 columns:
##' \describe{
##'   \item{id}{individual identifier}
##'   \item{date}{time of fix, POSIXct in UTC}
##'   \item{lc}{Argos location class, from most to least accurate: 3, 2, 1, 0, A, B, Z}
##'   \item{lon}{longitude in decimal degrees, WGS84}
##'   \item{lat}{latitude in decimal degrees, WGS84}
##' }
##' @keywords data
"ellie"

##' GPS tracks of immature northern gannets from the Bass Rock
##'
##' GPS tracks of three immature northern gannets (*Morus bassanus*) tagged at
##' the Bass Rock, Firth of Forth, in summer 2015. A subset of a larger
##' dataset, chosen so that the three birds between them span the North Sea
##' from Shetland to Dutch waters.
##'
##' @format A tibble with 8158 rows and 5 columns:
##' \describe{
##'   \item{id}{tag identifier, character}
##'   \item{trip}{foraging trip identifier, character, unique across birds}
##'   \item{datetime_utc}{time of fix, POSIXct in UTC}
##'   \item{lon}{longitude in decimal degrees, WGS84}
##'   \item{lat}{latitude in decimal degrees, WGS84}
##' }
##' @keywords data
##' @source Grecian et al. (2018) \doi{10.1098/rsif.2018.0084}
"gannets"
