d_input <- function() {
  tibble::tribble(
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
}

d_output <- function() {
  d_input() %>%
    dplyr::mutate(air.2m = c(279.1179, 279.1572, 294.1814, 296.8004, 277.0919),
           rhum.2m = c(70.18391, 81.42355, 76.55719, 76.65743, 73.23998))
}

test_that("addNarrData adds temp and humidity", {
  d <- get_narr_data(d_input(), narr_variables = c('air.2m', 'rhum.2m'))
  expect_equal(
    d$air.2m,
    d_output()$air.2m,
    tolerance = 0.0004
  )
  expect_equal(
    d$rhum.2m,
    d_output()$rhum.2m,
    tolerance = 0.0004
  )
})
