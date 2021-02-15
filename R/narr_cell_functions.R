r_narr_empty <- function() {
  raster::raster(
    nrows = 277,
    ncols = 349,
    xmn = -16231.49,
    xmx = 11313351,
    ymn = -16231.5,
    ymx = 8976020,
    crs = "+proj=lcc +x_0=5632642.22547 +y_0=4612545.65137 +lat_0=50 +lon_0=-107 +lat_1=50",
    resolution = c(32462.99, 32463),
    vals = NULL
  )
}

#' get NARR cell numbers for given lat and lon
#'
#' @param d data.frame with columns 'lat' and 'lon'
#'
#' @return a data.frame identical to the input data.frame but with appended NARR cell numbers
#'
#' @examples
#' if (FALSE) {
#' d <- data.frame(
#'   id = c('1a', '2b', '3c'),
#'   lat = c(39.19674, 39.19674, 39.48765),
#'   lon = c(-84.582601, -84.582601, -84.610173)
#' )
#'
#' get_narr_cell_numbers(d)
#' }
#' @export
get_narr_cell_numbers <- function(d) {
  if (!"lat" %in% colnames(d)) {
    stop("input dataframe must have a column called 'lat'")
  }

  if (!"lon" %in% colnames(d)) {
    stop("input dataframe must have a column called 'lon'")
  }

  d$.row <- seq_len(nrow(d))

  d_out <-
    d %>%
    dplyr::select(.row, lat, lon) %>%
    stats::na.omit() %>%
    tidyr::nest(.rows = c(.row)) %>%
    sf::st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
    sf::st_transform(crs = raster::crs(r_narr_empty())) # reproject points into NARR projection for overlay

  coords <- as.matrix(sf::st_coordinates(d_out))

  d_out <- d_out %>%
    dplyr::mutate(narr_cell = raster::cellFromXY(r_narr_empty(), coords))

  d_out <- d_out %>%
    tidyr::unnest(.rows) %>%
    sf::st_drop_geometry() %>%
    dplyr::left_join(d, ., by = ".row") %>%
    dplyr::select(-.row)

  return(d_out)
}






