#' Function to convert numeric ggplot axis to whole integers
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function takes a numeric vector as input and formats the resulting 
#' ggplot axis as whole integers (for when fractions don't make sense). The 
#' function can be passed to the `breaks` argument of `scale_y_continuous`. 
#'
#' @md
#' 
#' @param n approximate number of break-points to use
#' @param ... other optional arguments to pass to `breaks`
#' 
#' @return whole integer labels for a numeric axis
#'
#' @examples
#' \dontrun{
#' # Use function to set y axis breaks format:
#' scale_y_continuous(breaks = integer_breaks())
#' }
#' @export
integer_breaks <- function(n = 5, ...) {
  fxn <- function(x) {
    breaks <- floor(pretty(x, n, ...))
    names(breaks) <- attr(breaks, "labels")
    breaks
  }
  return(fxn)
}