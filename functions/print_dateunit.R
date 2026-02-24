#' Function to make aggregate date units human readable
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function takes year-week or year-month as 6 digit character strings and 
#' converts them into nice printable text for including in the text components 
#' of an R markdown report. For example, the year week "202345" would be 
#' converted to "45 2023" and the year month "202308" would be converted to
#' "August 2023" (or equivalent in other languages).  The function is language
#' agnostic.
#' 
#' Note: input date strings should be in the format YYYYWW or YYYYMM
#'
#' @md
#' 
#' @param aggdate The six-digit character string (year-week or year-month)
#' @param aggtype The type of date to convert, one of "week" or "month"
#' 
#' @return a human readable character string representing the input date unit
#'
#' @examples
#' # Convert a year week string to printable version:
#' print_dateunit(aggdate = "202345", aggtype = "week")
#' 
#' # Convert a year month string to printable version:
#' print_dateunit(aggdate = "202308", aggtype = "month")
#'
#' @export
print_dateunit <- function(aggdate, 
                           aggtype = c("week", "month")) {
  
  # Extract the year from the string:
  year = substr(x = aggdate, start = 1, stop = 4)
  
  # Extract the week or month from the string:
  wm = substr(x = aggdate, start = 5, stop = 6)
  
  # For year week:
  if(aggtype == "week") {
    
    # Paste the week number to a space and then year:
    formatted = paste(wm, year)
  }
  
  # For year month:
  if(aggtype == "month") {
    
    # Create a dummy date from the year and month:
    redate = as.Date(paste0(year, "-", wm, "-01"))
    
    # Select the display format as full month name and full year:
    formatted = format(x = redate, format = "%B %Y")
  }
  
  # Return the formatted object ready for inclusion in other text.
  return(formatted)
  
}