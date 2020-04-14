library(tidyverse)
library(fst)

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

  d <- d %>%
    split(d$narr_cell_number)

  return(map_dfr(d, ~read_narr_fst_join(.x, narr_variables)))
}


read_narr_fst_join <- function(d, narr_variables) {
  narr_cell_number <- unique(d$narr_cell_number)

  narr_row_start <- ((narr_cell_number - 1) * 7305) + 1
  narr_row_end <- narr_cell_number * 7305

  d <- d %>%
    mutate(row_index = seq_len(nrow(d))) %>%
    group_by(row_index) %>%
    nest() %>%
    mutate(date_seq = purrr::map(data, ~seq.Date(from = .x$start_date,
                                                 to = .x$end_date,
                                                 by = 1))) %>%
    unnest(cols = c(data, date_seq))

  out <-
    fst::read_fst(
      path = "./narr.fst",
      from = narr_row_start,
      to = narr_row_end,
      columns = c("narr_cell", "date", narr_variables),
      as.data.table = TRUE
    )

  out <- map_dfr(d$date_seq, ~out[.(data.table::CJ(narr_cell_number, .x)), nomatch = 0L])

  d <- d %>%
    left_join(out, by = c('date_seq' = 'date')) %>%
    ungroup() %>%
    select(-row_index) %>%
    group_by(MED_REC, VisitDate, start_date, end_date) %>%
    summarize_if(is.numeric, ~mean(., na.rm = T)) %>%
    select(-narr_cell)

  return(d)
}

