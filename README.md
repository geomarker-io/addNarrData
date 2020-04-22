
<!-- README.md is generated from README.Rmd. Please edit that file -->

# addNarrData

<!-- badges: start -->

<!-- badges: end -->

The goal of addNarrData is to add average NARR weather varaibles to your
data based on `narr_cell` (an identifier for a 12 x 12 km NARR grid
cell) and `start_date` and `end_date`.

## Installation

Install the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("geomarker-io/addNarrData")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(addNarrData)
#> narr.fst must be present in current working directory
library(magrittr)

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
#> # A tibble: 5 x 7
#>      id VisitDate  narr_cell start_date end_date   air.2m rhum.2m
#>   <dbl> <date>         <dbl> <date>     <date>      <dbl>   <dbl>
#> 1 51981 2017-03-08     56772 2017-03-01 2017-03-08   279.    70.2
#> 2 77553 2012-02-06     56772 2012-01-30 2012-02-06   279.    81.4
#> 3 78054 2017-09-20     56773 2017-09-13 2017-09-20   294.    76.6
#> 4 52284 2013-06-18     57121 2013-06-11 2013-06-18   297.    76.7
#> 5 96308 2019-02-25     57121 2019-02-18 2019-02-25   277.    73.2
```
