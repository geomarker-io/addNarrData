#' @keywords internal
"_PACKAGE"

# The following block is used by usethis to automatically manage
# roxygen namespace tags. Modify with care!
## usethis namespace: start
## usethis namespace: end
NULL

## quiets concerns of R CMD check around pipeline variables
if (getRversion() >= "2.15.1") utils::globalVariables(c("row_index", "data", "date_seq",
                                                        "lat", "lon", ".rows", ".",
                                                        "narr_chunk", "read_and_join"))
