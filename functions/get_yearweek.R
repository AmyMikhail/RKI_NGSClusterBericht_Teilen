#' Function to derive year and week from a date
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function will calculate the year and week from a formatted date (or 
#' column of dates). It uses ordinary years and weeks as these are primarily 
#' for using as labels in tables and graphs. Note that this means weeks at the 
#' end and beginning of years with 53 ISO weeks will therefore be different 
#' lengths (number of days).
#'
#' @md
#'
#' @import lubridate
#' @import dplyr
#' 
#' @param datecol vector of dates (date class) to convert to year-week
#' 
#' @return vector of year-weeks as 6-digit character strings (YYYYWW)
#'
#' @examples
#' # Get the year-week for today's date:
#' get_yearweek(Sys.Date())
#'
#' @export
get_yearweek <- function(datecol){
  
  # Extract the year from the date:
  yearcol = lubridate::year(datecol)
  
  # Extract the week number from the date:
  weekcol = lubridate::week(datecol) 
  
  # Paste them together with leading 0 for single-digit weeks:
  yearweekcol = paste0(yearcol, 
                       ifelse(nchar(weekcol) == 2, 
                              weekcol, 
                              paste0("0", weekcol))) 
  
  # Return NA if year and week produce NAs:
  yearweekcol = na_if(x = yearweekcol, y = "NANA")
  
  # Return the year-week:
  return(yearweekcol)
  
}