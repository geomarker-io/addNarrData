d_input <- function() {
  tibble::tibble(
  id = c('1a', '2b', '3c'),
  visit_date = c("3/8/17", "2/6/12", "6/18/20"),
  lat = c(39.19674, 39.19674, 39.48765),
  lon = c(-84.582601, -84.582601, -84.610173)
  ) %>%
  dplyr::mutate(
    visit_date = as.Date(visit_date, format = "%m/%d/%y"),
    start_date = visit_date - lubridate::days(7), # weekly average
    end_date = visit_date
  )
}

d_output <- function() {
  d_input() %>%
    dplyr::mutate(air.2m = c(292.1765, 279.1179, 279.1572),
           rhum.2m = c(70.95600, 70.18391, 81.42355))
}

test_that("addNarrData adds temp and humidity", {
  d_narr_cell <- get_narr_cell_numbers(d_input())

  download_narr_fst()

  d <- get_narr_data(d_narr_cell,
                     narr_variables = c('air.2m', 'rhum.2m'))
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
