# Packages listed in Imports that mapr needs but never calls directly.
# Referencing them here tells R CMD check the dependency is deliberate.
# The function is never run.
#
#   rnaturalearthdata  supplies the medium-scale coastline that
#                      rnaturalearth::ne_countries() reads in mapr()
#   sp                 needed by sf::as_Spatial() in meshr()
#   tibble             the example datasets are tibbles; importing it
#                      means they print as tibbles for every user
ignore_unused_imports <- function() {
  rnaturalearthdata::countries50
  sp::CRS
  tibble::tibble
}
