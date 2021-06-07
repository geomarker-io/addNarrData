
<!-- README.md is generated from README.Rmd. Please edit that file -->

# addNarrData

<!-- badges: start -->

[![R build
status](https://github.com/geomarker-io/addNarrData/workflows/R-CMD-check/badge.svg)](https://github.com/geomarker-io/addNarrData/actions)
<!-- badges: end -->

The goal of addNarrData is to add average NARR weather varaibles to data
based on `narr_cell` (an identifier for a 12 x 12 km NARR grid cell) and
`start_date` and `end_date`.

NARR Data Dictionary

| Variable Name | Description                     |
|:--------------|:--------------------------------|
| hpbl          | Planetary Boundary Layer Height |
| vis           | Visibility                      |
| uwnd.10m      | U Wind Speed at 10m             |
| vwnd.10m      | V Wind Speed at 10m             |
| air.2m        | Air Temperature at 2m           |
| rhum.2m       | Humidity at 2m                  |
| prate         | Precipitation Rate              |
| pres.sfc      | Surface Pressure                |

More information is available at the
[NOAA](https://www.ncdc.noaa.gov/sites/default/files/attachments/ncdc-narrdsi-6175-final.pdf)
website.

## Installation

Install from [GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("geomarker-io/addNarrData")
```

## Example Usage

add NARR data.

``` r
library(addNarrData)
library(magrittr)

d <- tibble::tibble(
  id = c('1a', '2b', '3c'),
  visit_date = c("3/8/17", "2/6/12", "6/18/20"),
  lat = c(39.19674, 39.19674, 39.48765),
  lon = c(-84.582601, -84.582601, -84.610173)
)

d %>%
  dplyr::mutate(
    visit_date = as.Date(visit_date, format = "%m/%d/%y"),
    start_date = visit_date - lubridate::days(7), # weekly average
    end_date = visit_date
    ) %>%
  get_narr_data(narr_variables = c("air.2m", "rhum.2m"))
#> ℹ 2 total files will be required (1 chunks for 2 narr variables)
#> ℹ all files already exist
#>     narr_cell       date id visit_date      lat       lon start_date   end_date
#>  1:     56423 2020-06-11 3c 2020-06-18 39.48765 -84.61017 2020-06-11 2020-06-18
#>  2:     56423 2020-06-12 3c 2020-06-18 39.48765 -84.61017 2020-06-11 2020-06-18
#>  3:     56423 2020-06-13 3c 2020-06-18 39.48765 -84.61017 2020-06-11 2020-06-18
#>  4:     56423 2020-06-14 3c 2020-06-18 39.48765 -84.61017 2020-06-11 2020-06-18
#>  5:     56423 2020-06-15 3c 2020-06-18 39.48765 -84.61017 2020-06-11 2020-06-18
#>  6:     56423 2020-06-16 3c 2020-06-18 39.48765 -84.61017 2020-06-11 2020-06-18
#>  7:     56423 2020-06-17 3c 2020-06-18 39.48765 -84.61017 2020-06-11 2020-06-18
#>  8:     56423 2020-06-18 3c 2020-06-18 39.48765 -84.61017 2020-06-11 2020-06-18
#>  9:     56772 2012-01-30 2b 2012-02-06 39.19674 -84.58260 2012-01-30 2012-02-06
#> 10:     56772 2012-01-31 2b 2012-02-06 39.19674 -84.58260 2012-01-30 2012-02-06
#>       air.2m  rhum.2m
#>  1: 293.4990 76.07307
#>  2: 292.9222 62.71841
#>  3: 291.3193 68.94843
#>  4: 289.9917 74.19376
#>  5: 289.4601 76.40369
#>  6: 291.8245 73.69858
#>  7: 293.2501 69.98094
#>  8: 295.1451 65.63108
#>  9: 277.3686 83.29338
#> 10: 284.2750 85.39286
#>  [ reached getOption("max.print") -- omitted 15 rows ]
```

### NARR data files

The package works by downloading chunks of NARR data automagically.
These are stored in an Amazon s3 drive at

    s3://geomarker/narr/narr_chunk_fst/narr_chunk_{number}_{variable}.fst

where `{number}` is replaced with the NARR chunk number (0 - 9), and
`{variable}` is replaced with one of the available NARR variables
(`hpbl`, `vis`, `rhum.2m`, `prate`, `air.2m`, `pres.sfc`, `uwnd.10m`,
`vwnd.10m`). Each file is about 350 MB in size, but only the files
needed will be downloaded.

More information on the NARR fst chunk files can be found at
[narr\_raster\_to\_fst](https://github.com/geomarker-io/narr_raster_to_fst#narr_raster_to_fst).
