
<!-- README.md is generated from README.Rmd. Please edit that file -->

# addNarrData

<!-- badges: start -->

[![R build
status](https://github.com/geomarker-io/addNarrData/workflows/R-CMD-check/badge.svg)](https://github.com/geomarker-io/addNarrData/actions)
<!-- badges: end -->

The goal of addNarrData is to add average NARR weather varaibles to data
based on `narr_cell` (an identifier for a 12 x 12 km NARR grid cell) and
`start_date` and `end_date`.

## Installation

Install from [GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("geomarker-io/addNarrData")
```

### NARR data files

The NARR values are stored in chunk files in an Amazon s3 drive at

    s3://geomarker/narr/narr_chunk_fst/narr_chunk_{number}_{variable}.fst

where `{number}` is replaced with the NARR chunk number (0 - 9), and
`{variable}` is replaced with one of the available NARR variables
(`hpbl`, `vis`, `rhum.2m`, `prate`, `air.2m`, `pres.sfc`, `uwnd.10m`,
`vwnd.10m`). Each file is about 350 MB in size, but only the files
needed will be downloaded.

More information on the NARR fst chunk files can be found at
[narr\_raster\_to\_fst](https://github.com/geomarker-io/narr_raster_to_fst#narr_raster_to_fst).

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
get_narr_data(d_narr_cell, narr_variables = c('air.2m', 'rhum.2m'))
#> downloading narr fst chunk files for chunk number 5...
#> ℹ all files already exist
#> reading in /Users/RASV5G/OneDrive - cchmc/addNarrData/s3_downloads/geomarker/narr/narr_chunk_fst/narr_chunk_5_air.2m.fst and joining to data...
#> reading in /Users/RASV5G/OneDrive - cchmc/addNarrData/s3_downloads/geomarker/narr/narr_chunk_fst/narr_chunk_5_rhum.2m.fst and joining to data...
#> Joining, by = c("narr_cell", "date", "id", "visit_date", "lat", "lon", "start_date", "end_date", "narr_chunk")
#> # A tibble: 24 x 11
#>    narr_cell date       id    visit_date   lat   lon start_date end_date  
#>        <int> <date>     <chr> <date>     <dbl> <dbl> <date>     <date>    
#>  1     56423 2020-06-11 3c    2020-06-18  39.5 -84.6 2020-06-11 2020-06-18
#>  2     56423 2020-06-12 3c    2020-06-18  39.5 -84.6 2020-06-11 2020-06-18
#>  3     56423 2020-06-13 3c    2020-06-18  39.5 -84.6 2020-06-11 2020-06-18
#>  4     56423 2020-06-14 3c    2020-06-18  39.5 -84.6 2020-06-11 2020-06-18
#>  5     56423 2020-06-15 3c    2020-06-18  39.5 -84.6 2020-06-11 2020-06-18
#>  6     56423 2020-06-16 3c    2020-06-18  39.5 -84.6 2020-06-11 2020-06-18
#>  7     56423 2020-06-17 3c    2020-06-18  39.5 -84.6 2020-06-11 2020-06-18
#>  8     56423 2020-06-18 3c    2020-06-18  39.5 -84.6 2020-06-11 2020-06-18
#>  9     56772 2012-01-30 2b    2012-02-06  39.2 -84.6 2012-01-30 2012-02-06
#> 10     56772 2012-01-31 2b    2012-02-06  39.2 -84.6 2012-01-30 2012-02-06
#> # … with 14 more rows, and 3 more variables: narr_chunk <dbl>,
#> #   air.2m <dbl>, rhum.2m <dbl>
```
