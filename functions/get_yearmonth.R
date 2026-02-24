#' Function to derive year and calendar month from a date
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function will calculate the year and calendar month from a formatted 
#' date (or column of dates). It uses ordinary years and months as these are 
#' primarily for using as labels in tables and graphs. 
#'
#' @md
#'
#' @import lubridate
#' @import dplyr
#' 
#' @param datecol Vector of dates (date class) to convert to year-months
#' 
#' @return Vector of 6-digit year-months (format YYYYMM)
#'
#' @examples
#' # Get the year-month for today's date:
#' get_yearmonth(Sys.Date())
#'
#' @export
get_yearmonth <- function(datecol){
  
  # Extract year from date:
  yearcol = lubridate::year(datecol)
  
  # Extract month from date:
  monthcol = lubridate::month(datecol) 
  
  # Paste them together with leading 0 for single-digit months:
  yearmonthcol = paste0(yearcol, 
                        ifelse(nchar(monthcol) == 2, 
                               monthcol, 
                               paste0("0", monthcol))) 
  
  # Replace with NA if year and month return NAs:
  yearmonthcol = na_if(x = yearmonthcol, y = "NANA")
  
  # Return the year-month:
  return(yearmonthcol)
  
}