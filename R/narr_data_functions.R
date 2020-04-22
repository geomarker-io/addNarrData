#' @import data.table

read_narr_fst_join <- function(d_one, narr_variables, narr_fst_filepath) {
  d_orig <- d_one
  d_orig$row_index <- seq_len(nrow(d_orig))

  narr_cell <- unique(d_one$narr_cell)
  narr_row_start <- ((narr_cell - 1) * 7305) + 1
  narr_row_end <- narr_cell * 7305

  d_one <-
    d_one %>%
    dplyr::mutate(row_index = seq_len(nrow(d_one))) %>%
    dplyr::group_by(row_index) %>%
    tidyr::nest() %>%
    dplyr::mutate(date_seq = purrr::map(data, ~ seq.Date(.$start_date, .$end_date, by = 1))) %>%
    tidyr::unnest(cols = c(data, date_seq)) %>%
    dplyr::select(row_index, narr_cell, date = date_seq)

  out <-
    fst::read_fst(
      path = narr_fst_filepath,
      from = narr_row_start,
      to = narr_row_end,
      columns = c("narr_cell", "date", narr_variables),
      as.data.table = TRUE
    )

  # subset to all dates needed for the narr cell number
  out <- out[list(data.table::CJ(narr_cell, unique(d_one$date))), nomatch = 0L]

  d_one <- dplyr::left_join(d_one, out, by = c("date", "narr_cell"))

  d_out <-
    d_one %>%
    dplyr::group_by(row_index) %>%
    dplyr::summarize_at(tidyselect::all_of(narr_variables), mean, na.rm = TRUE)

  dplyr::left_join(d_orig, d_out, by = "row_index") %>%
    dplyr::select(-row_index)
}

#' get averaged NARR data for NARR cells and start and end dates
#'
#' @param d data.frame with columns 'narr_cell', 'start_date', and 'end_date'
#' @param narr_variables a character string of desired narr variables; a subset of c("hpbl", "vis", "uwnd.10m", "vwnd.10m", "air.2m", "rhum.2m", "prate", "pres.sfc")
#' @param narr_fst_filepath manually specificy a file path to the narr.fst file; normally this would be left unset (defaults to NULL) to use narr.fst in the application data folder (or in the working directory)
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
                            "air.2m", "rhum.2m", "prate", "pres.sfc"
                          ),
                          narr_fst_filepath = NULL) {
  if (is.null(narr_fst_filepath)) {
    narr_fst_filepath <- narr_fst()
  }

  if (!"narr_cell" %in% colnames(d)) {
    stop("input dataframe must have a column called 'narr_cell'")
  }
  if (!"start_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'start_date'")
  }
  if (!"end_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'end_date'")
  }

  d <- split(d, d$narr_cell)

  return(purrr::map_dfr(d, ~ read_narr_fst_join(.x, narr_variables, narr_fst_filepath = narr_fst_filepath)))
}

#' download narr.fst file to application specific directory so that it can be shared across R sessions and projects
#' @export
download_narr_fst <- function() {
  narr_fl_appdir <- fs::path(rappdirs::site_data_dir("addNarrData"), "narr.fst")

  if (!file.exists(narr_fl_appdir)) {
    message("This package requires a local copy of s3://geomarker/narr/narr.fst in order to lookup NARR values; it is 20 GB in size and will be downloaded to ", narr_fl_appdir, " so it can be shared across R sessions and projects.")
    ans <- readline("Do you want to download this now (Y/n)? ")
    if (!ans %in% c("", "y", "Y")) stop("aborted", call. = FALSE)

    utils::download.file("https://geomarker.s3.us-east-2.amazonaws.com/narr/narr.fst", narr_fl_appdir)
  }
}


#' checks for and returns filepath to narr.fst file in application-specific site data directory or current working directory
#' if not found, fails with suggestion to run download_narr_fst()
narr_fst <- function() {
  narr_fl_appdir <- fs::path(rappdirs::site_data_dir("addNarrData"), "narr.fst")
  narr_fl_wd <- fs::path(getwd(), "narr.fst")

  if (file.exists(narr_fl_wd)) {
    message("using narr.fst file at ", narr_fl_wd)
    return(invisible(narr_fl_wd))
  }

  if (file.exists(narr_fl_appdir)) {
    message("using narr.fst file at ", narr_fl_appdir)
    return(invisible(narr_fl_appdir))
  }

  stop("narr.fst file not found at\n    ", narr_fl_appdir, "\n    or at\n    ", narr_fl_wd, "\n please call download_narr_fst() to download this file", call. = FALSE)
}
