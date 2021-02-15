
<!-- README.md is generated from README.Rmd. Please edit that file -->

# addNarrData

<!-- badges: start -->

[![R build
status](https://github.com/geomarker-io/addNarrData/workflows/R-CMD-check/badge.svg)](https://github.com/geomarker-io/addNarrData/actions)
<!-- badges: end -->

The goal of addNarrData is to add average NARR weather varaibles to your
geocoded data by matching coordinates to a `narr_cell` (an identifier for 
a 12 x 12 km NARR grid cell) and `start_date` and `end_date`.

## Installation

Install the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("geomarker-io/addNarrData")
```

### NARR database file

The NARR values are stored in `narr.fst` (20 GB in size), which can
either be located in the working directory, or preferably within the
platform-specific user data directory so it can be shared across R
sessions and projects. If needed, you will be prompted to run
`download_narr_fst()` the first time you call `get_narr_data()`. This 22
GB file is a large file to download, but will only need to be done once
per user and computer.

## Example

Get NARR cell numbers.

``` r
library(addNarrData)
library(magrittr)

d <- tibble::tibble(
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

d_narr_cell <- get_narr_cell_numbers(d)
```

Add NARR data.

``` r
download_narr_fst()
```

``` r
get_narr_data(d_narr_cell, narr_variables = c('air.2m', 'rhum.2m'))
#> using narr.fst file at ~/Library/Application Support/addNarrData/geomarker/narr/narr.fst
#> # A tibble: 3 x 9
#>   id    visit_date   lat   lon start_date end_date   narr_cell air.2m
#>   <chr> <date>     <dbl> <dbl> <date>     <date>         <dbl>  <dbl>
#> 1 3c    2020-06-18  39.5 -84.6 2020-06-11 2020-06-18     56423   292.
#> 2 1a    2017-03-08  39.2 -84.6 2017-03-01 2017-03-08     56772   279.
#> 3 2b    2012-02-06  39.2 -84.6 2012-01-30 2012-02-06     56772   279.
#> # … with 1 more variable: rhum.2m <dbl>
```
