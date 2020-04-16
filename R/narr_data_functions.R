.onAttach <- function() {
  if (!file.exists("./narr.fst")) {
    message("narr.fst must be present in current working directory")
  }
}

#' get averaged NARR data for NARR cells and start and end dates
#'
#' @param d data.frame with columns 'narr_cell' , 'start_date', and 'end_date'
#' @param narr_variables a character string of desired narr variables; a subset of c("hpbl", "vis", "uwnd.10m", "vwnd.10m", "air.2m", "rhum.2m", "prate", "pres.sfc")
#'
#' @return a data.frame identical to the input data.frame but with appended average NARR values
#'
#' @examples
#' my_data <- data.frame(id = 1:3,
#'     lat = c(39.19674, 39.12731,	39.28765),
#'     lon = c(-84.58260, -84.52700, -84.51017))
#'
#' ecat_est <- calculate_ecat(my_data, return.LU.vars = FALSE)
#' ecat_est <- calculate_ecat(my_data, return.LU.vars = TRUE)
#' @export
get_narr_data <- function(d,
                          narr_variables = c(
                            "hpbl", "vis", "uwnd.10m", "vwnd.10m",
                            "air.2m", "rhum.2m", "prate", "pres.sfc"
                          )) {

  if(!"narr_cell" %in% colnames(d)) {stop("input dataframe must have a column called 'narr_cell'")}
  if(!"start_date" %in% colnames(d)) {stop("input dataframe must have a column called 'start_date'")}
  if(!"end_date" %in% colnames(d)) {stop("input dataframe must have a column called 'end_date'")}

  d <- split(d, d$narr_cell)

  return(purrr::map_dfr(d, ~read_narr_fst_join(.x, narr_variables)))
}


read_narr_fst_join <- function(d_one = d[[1]], narr_variables) {
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
      path = "./narr.fst",
      from = narr_row_start,
      to = narr_row_end,
      columns = c("narr_cell", "date", narr_variables),
      as.data.table = TRUE
    )

  # subset to all dates needed for the narr cell number
  out <- out[.(data.table::CJ(narr_cell, unique(d_one$date))), nomatch = 0L]

  d_one <- dplyr::left_join(d_one, out, by = c("date", "narr_cell"))

  d_out <-
    d_one %>%
    dplyr::group_by(row_index) %>%
    dplyr::summarize_at(tidyselect::all_of(narr_variables), mean, na.rm = TRUE)

  dplyr::left_join(d_orig, d_out, by = "row_index") %>%
    dplyr::select(-row_index)
}

