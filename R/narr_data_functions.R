.onAttach <- function(libname, pkgname) {
  if(!file.exists("./narr.fst")) {message("narr.fst must be present in current working directory")}
}

get_narr_data <- function(d,
                          narr_variables = c(
                            "hpbl", "vis", "uwnd.10m", "vwnd.10m",
                            "air.2m", "rhum.2m", "prate", "pres.sfc"
                          )) {

  if(!"narr_cell_number" %in% colnames(d)) {stop("input dataframe must have a column called 'narr_cell_number'")}
  if(!"start_date" %in% colnames(d)) {stop("input dataframe must have a column called 'start_date'")}
  if(!"end_date" %in% colnames(d)) {stop("input dataframe must have a column called 'end_date'")}

  d <- split(d, d$narr_cell_number)

  return(purrr::map_dfr(d, ~read_narr_fst_join(.x, narr_variables)))
}


read_narr_fst_join <- function(d, narr_variables) {
  d_orig <- d

  narr_cell_number <- unique(d$narr_cell_number)
  narr_row_start <- ((narr_cell_number - 1) * 7305) + 1
  narr_row_end <- narr_cell_number * 7305

  d$row_index <- seq_len(nrow(d))
  d <- dplyr::group_by(d, row_index)
  d <- tidyr::nest(d)
  d <- dplyr::mutate(d, date_seq = purrr::map(data, ~seq.Date(from = .x$start_date,
                                                              to = .x$end_date,
                                                              by = 1)))
  d <- tidyr::unnest(d, cols = c(data, date_seq))
  d <- dplyr::select(d, row_index, narr_cell_number, start_date, end_date, date_seq)

  out <-
    fst::read_fst(
      path = "./narr.fst",
      from = narr_row_start,
      to = narr_row_end,
      columns = c("narr_cell", "date", narr_variables),
      as.data.table = TRUE
    )

  out <- purrr::map_dfr(d$date_seq, ~out[.(data.table::CJ(narr_cell_number, .x)), nomatch = 0L])

  d <- dplyr::left_join(d, out, by = c('date_seq' = 'date'))
  d <- dplyr::ungroup(d)
  d <- dplyr::group_by(d, row_index, start_date, end_date)
  d <- dplyr::summarize_if(d, is.numeric, ~mean(., na.rm = T))
  d <- dplyr::select(d, -narr_cell, -narr_cell_number)

  d <- dplyr::left_join(d_orig, d, by = c('start_date', 'end_date'))
  d <- dplyr::select(d, -row_index)

  return(d)
}

