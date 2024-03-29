#' get averaged NARR data for lat, lon, start_date, and end_date
#'
#' @param d data.frame with columns 'lat', 'lon', 'start_date', and 'end_date'
#' @param type type of input data. either 'coords' if starting from lat and lon columns, or 'narr_cell'
#'             if starting from narr cell ids.
#' @param narr_variables a character string of desired narr variables; a subset of c("hpbl", "vis", "uwnd.10m", "vwnd.10m", "air.2m", "rhum.2m", "prate", "pres.sfc")
#' @param ... further arguments passed onto s3::s3_get_files
#'
#' @return a data.frame identical to the input data.frame but with appended average NARR values
#'
#' @examples
#' if (FALSE) {
#' d <- data.frame(
#'   id = c('1a', '2b', '3c'),
#'   lat = c(39.19674, 39.19674, 39.48765),
#'   lon = c(-84.582601, -84.582601, -84.610173),
#'   start_date = as.Date(c("3/8/17", "2/6/12", "6/18/20"), format = "%m/%d/%y"),
#'   end_date = as.Date(c("3/15/17", "2/13/12", "6/25/20"), format = "%m/%d/%y")
#' )
#'
#' get_narr_data(d, narr_variables = c("air.2m", "rhum.2m"))
#' }
#' @import data.table
#' @export
get_narr_data <- function(d, type = 'coords',
                          narr_variables = c(
                            "hpbl", "vis", "uwnd.10m", "vwnd.10m",
                            "air.2m", "rhum.2m", "prate", "pres.sfc"),
                          ...
                          ) {

  d$row_index <- 1:nrow(d)

  if (type == 'narr_cell') {
    dht::check_for_column(d, 'narr_cell', d$narr_cell, 'numeric')
    d_missing <- d %>% dplyr::filter(is.na(narr_cell))
    d <- dplyr::filter(d, !is.na(narr_cell))
  } else {
    d_missing <- d %>% dplyr::filter(is.na(lat), is.na(lon))
    d <- dplyr::filter(d, !is.na(lat), !is.na(lon))
    d <- get_narr_cell_numbers(d)
  }

  if (!"start_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'start_date'")
  }
  if (!"end_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'end_date'")
  }
  if(TRUE %in% (d$start_date < "2000-01-01" | d$end_date > "2020-12-31")) {
    cli::cli_alert_warning("NARR data is available for years 2000 - 2020; Data will be missing for dates outside this range.")
  }

  d$narr_chunk <- d$narr_cell %/% 10000

  narr_chunks <-
    purrr::map(
      d$narr_chunk,
      ~ paste(., narr_variables, sep = "_")
    ) %>%
    unlist() %>%
    unique()

  d <-
    dht::expand_dates(d, by = "day") %>%
    as.data.table(key = c("narr_cell", "date"))

  d <- dplyr::nest_by(d, narr_chunk)

  d$narr_uris <-
    purrr::map(
    d$narr_chunk,
    ~ glue::glue("s3://geomarker/narr/narr_chunk_fst/narr_chunk_{.}_{narr_variables}.fst")
  )

  cli::cli_alert_info(c(
    "{length(unlist(d$narr_uris))} ",
    "total file{?s} will be required ",
    "({length(d$narr_chunk)} chunk{?s} ",
    "for {length(narr_variables)} narr variable{?s})"
  ))

  narr_chunk_files <- s3::s3_get_files(unlist(d$narr_uris), public = TRUE, ...)

  read_and_join <- function(.x, narr_fst_uris) {
    pb$tick()
    d_narr <- tibble::tibble(uri = narr_fst_uris)
    d_narr <- dplyr::left_join(d_narr, narr_chunk_files, by = c("uri"))
    merged_fst <-
      purrr::map(d_narr$file_path, fst::read_fst, as.data.table = TRUE) %>%
      purrr::reduce(data.table::merge.data.table, all.x = TRUE, by = c("narr_cell", "date")) %>%
      data.table::merge.data.table(x = as.data.table(.x), y = ., all.x = TRUE, by = c("narr_cell", "date"))
    return(merged_fst)
  }

  pb <- progress::progress_bar$new(
    format = "  processing :current of :total chunks eta: :eta (elapsed: :elapsed)",
    total = nrow(d), clear = FALSE)

  pb$tick(0)

  d$narr_data <- purrr::map2(d$data, d$narr_uris, read_and_join)
  out <- dplyr::bind_rows(d$narr_data)
  out <- dplyr::bind_rows(d_missing, out) %>%
    dplyr::arrange(row_index) %>%
    dplyr::select(-row_index)

  return(out)
}
