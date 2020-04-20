library(magrittr)
source('./R/narr_data_functions.R')

d <- tibble::tribble(
  ~id, ~VisitDate, ~narr_cell,
  51981, "3/8/17", 56772,
  77553, "2/6/12", 56772,
  52284, "6/18/13", 57121,
  96308, "2/25/19", 57121,
  78054, "9/20/17", 56773
) %>%
  dplyr::mutate(
    VisitDate = as.Date(VisitDate, format = "%m/%d/%y"),
    start_date = VisitDate - lubridate::days(7),
    end_date = VisitDate
  )

get_narr_data(d, narr_variables = c('air.2m', 'rhum.2m'))


