d_input <- function() {
  tibble::tibble(
  id = c('1a', '2b', '3c'),
  visit_date = c("3/8/17", "2/6/12", "6/18/20"),
  lat = c(39.19674, 39.19674, 37.70824),
  lon = c(-84.582601, -84.582601, -121.15745)
  ) %>%
  dplyr::mutate(
    visit_date = as.Date(visit_date, format = "%m/%d/%y"),
    start_date = visit_date - lubridate::days(7), # weekly average
    end_date = visit_date
  )
}

d_output <- function() {
  data.frame(
    air.2m = c(277.802947998047, 274.185699462891, 273.358459472656, 276.449645996094,
               282.496307373047, 285.909545898438, 281.431213378906, 281.308990478516,
               277.368591308594, 284.275024414062, 282.665435791016, 279.237945556641,
               278.376251220703, 278.684448242188, 276.294677734375, 276.355377197266,
               299.866180419922, 296.547180175781, 288.350524902344, 291.35888671875,
               296.421020507812, 294.691711425781, 295.515747070312, 297.551361083984
               ),
    rhum.2m = c(63.9534950256348, 60.0151062011719, 68.427734375, 67.0569229125977,
                86.4392471313477, 89.8799896240234, 67.7536544799805, 57.9451217651367,
                83.2933807373047, 85.3928604125977, 77.0471649169922, 77.7499542236328,
                87.7021102905273, 86.5066757202148, 76.89892578125, 76.7973403930664,
                23.7136936187744, 34.8980903625488, 57.1124992370605, 46.0843811035156,
                36.6224517822266, 30.393892288208, 25.9887504577637, 18.3810844421387
    )
  )
}

test_that("addNarrData adds temp and humidity", {
  d <- get_narr_data(d_input(),
                     narr_variables = c('air.2m', 'rhum.2m'),
                     confirm = FALSE)
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

d_input_cell <- function() {
  tibble::tibble(
    id = c('1a', '2b', '3c'),
    visit_date = c("3/8/17", "2/6/12", "6/18/20"),
    narr_cell = c('56772', '56772', '60512')
  ) %>%
    dplyr::mutate(
      visit_date = as.Date(visit_date, format = "%m/%d/%y"),
      start_date = visit_date - lubridate::days(7), # weekly average
      end_date = visit_date,
      narr_cell = as.numeric(narr_cell)
    )
}

test_that("addNarrData adds temp and humidity", {
  d <- get_narr_data(d_input_cell(), type = 'narr_cell',
                     narr_variables = c('air.2m', 'rhum.2m'),
                     confirm = FALSE)
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
