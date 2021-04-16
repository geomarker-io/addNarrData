#' @import data.table

read_join_chunks <- function(d_one, narr_chunk_path) {
  message('reading in ', narr_chunk_path, ' and joining to data...')
  narr_chunk <- fst::read_fst(narr_chunk_path, as.data.table = TRUE)
  d_out <- merge(data.table::as.data.table(d_one), narr_chunk, by = c("narr_cell", "date"))
  remove(narr_chunk)
  return(d_out)
}

download_join_chunks <- function(d_one, narr_product) {
  narr_chunk <- unique(d_one$narr_chunk)
  message('downloading narr fst chunk files for chunk number ', narr_chunk, '...')
  narr_chunk_path <- glue::glue("s3://geomarker/narr/narr_chunk_fst/narr_chunk_{narr_chunk}_{narr_product}.fst") %>%
    s3::s3_get_files()
  d_narr_chunk <- purrr::map(narr_chunk_path$file_path, ~read_join_chunks(d_one, .x))
  d_narr_chunk <- purrr::reduce(d_narr_chunk, dplyr::left_join)
  return(tibble::as_tibble(d_narr_chunk))
}

#' get averaged NARR data for NARR cells and start and end dates
#'
#' @param d data.frame with columns 'lat', 'lon', 'start_date', and 'end_date'
#' @param narr_variables a character string of desired narr variables; a subset of c("hpbl", "vis", "uwnd.10m", "vwnd.10m", "air.2m", "rhum.2m", "prate", "pres.sfc")
#' @param ... further arguments passed onto s3::s3_get_files
#'
#' @return a data.frame identical to the input data.frame but with appended average NARR values
#'
#' @examples
#' if (FALSE) {
#' d <- data.frame(
#'   id = c(51981, 77553, 52284),
#'   narr_cell = c(56772, 56772, 57121),
#'   start_date = as.Date(c("2017-03-01", "2012-01-30", "2013-06-11")),
#'   end_date = as.Date(c("2017-03-08", "2012-02-06", "2013-06-18"))
#' )
#'
#' get_narr_data(d, narr_variables = c("air.2m", "rhum.2m"))
#' }
#' @export
get_narr_data <- function(d,
                          narr_variables = c(
                            "hpbl", "vis", "uwnd.10m", "vwnd.10m",
                            "air.2m", "rhum.2m", "prate", "pres.sfc")
                          ) {

  if (!"narr_cell" %in% colnames(d)) {
    stop("input dataframe must have a column called 'narr_cell'")
  }
  if (!"start_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'start_date'")
  }
  if (!"end_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'end_date'")
  }

  d$narr_chunk <- d$narr_cell %/% 10000
  d <- dht::expand_dates(d, by = 'day')
  d_split <- split(d, d$narr_chunk)

  return(purrr::map_dfr(d_split, ~ download_join_chunks(.x, narr_variables)))
}
