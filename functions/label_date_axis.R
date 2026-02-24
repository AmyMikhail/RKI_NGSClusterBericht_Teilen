#' Function to add a second date axis with year to epicurves
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function will convert a vector of dates to labels for a date axis with
#' either weeks or months on the top line and year on the second line.  Years 
#' are not duplicated and separated by a dividing line to give an MS Excel date
#' axis - like effect.  The function can be passed to the `labels` argument of
#' `scale_x_dates` in a ggplot graph to format the axis. 
#'
#' @md
#'
#' @import lubridate
#' @import dplyr
#' @import stringr
#' 
#' @param dates Vector of dates (date class) to convert to double date axis
#' @param firstline element for first line of axis (weeks '%W' or months '%b')
#' 
#' @return double date axis labels with year on bottom to use on ggplot graph
#'
#' @examples
#' \dontrun{
#' # Pass 2-digit week as the format to use for the first line:
#' epicurve_labels <- "%W"
#' 
#' # Use the function to label a ggplot axis:
#' scale_x_date(date_breaks = "week", 
#'              minor_breaks = NULL, 
#'              expand = expansion(add = 3), 
#'              labels = label_date_axis)
#' }
#' @export
label_date_axis <- function(x, firstline = epicurve_labels) {
  prefix = strftime(x, format = firstline)
  years = lubridate::year(x)
  if_else(is.na(lag(years)) | lag(years) != years,
          true = stringr::str_glue("**| {prefix}<br>|<br>| {years}**"), 
          false = stringr::str_glue(" {prefix}"))
}