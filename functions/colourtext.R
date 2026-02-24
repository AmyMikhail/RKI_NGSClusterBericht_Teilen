#' Function to conditionally add emphasis to text in an R markdown document
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function is used to conditionally highlight a word, phrase or number 
#' when an R markdown document is knit to Microsoft Word. The function depends 
#' on the existence of a data.frame called 'compare' which compares new and old
#' values and indicates that the new values should be highlighted (TRUE) if 
#' they are different to the old values, otherwise no highlighting is applied
#' (FALSE). 
#' 
#' Note: this is a helper function and won't work independently of the function
#' that creates the 'compare' table.  The text to highlight should be selected 
#' by supplying the name of the text object (in the 'name' column of compare) 
#' as a character string to the 'filtername' argument.
#'
#' @md
#' 
#' @import dplyr
#' @import officer
#' 
#' @param filtername Character string with name of text object to format
#' 
#' @return character string in bold blue text (unless emphasize = FALSE)
#'
#' @examples
#' # Create the 'compare' data that defines if things get formatted or not:
#' compare <- data.frame(name = c("n_cases"), 
#'                       value_current = c("158"), 
#'                       vaue_previous = c("97"), 
#'                       change = c(TRUE))
#' 
#' # Because change = TRUE, the text will be highlighted in the output
#' # If change = FALSE, the text will not be highlighted in the output
#' 
#' \donttest{
#' # Conditionally emphasise the value of n_cases when the Rmd is knit: 
#' "There are `r colourtext("n_cases")` cases in the hospital."
#' }
#' 
#' @export
colourtext <- function(filtername){
  

# Set style using officer -------------------------------------------------

  # Set emphasise text style to RKI blue and bold:
  hstyle = officer::fp_text(color = "#4F81BD", 
                            bold = TRUE, 
                            font.size = 10, 
                            font.family = "Calibri")
  
  

# Structure of expected data ----------------------------------------------

# Expects a data set called 'compare' to exist in environment
  # - Names to filter on are in the 'name' column
  # - Values to format and print are in the 'value_current' column
  # - Logical indicator of whether to format or not is in the 'change' column
  
  # Check if 'compare' data exists:
  if(!exists("compare") | (exists("compare") & !is.data.frame(compare))){
    
    stopifnot("The source data for text to highlight does not exist or is in the 
              wrong format.  Please create the 'compare' data and try again.")
    
  } else {
    

# Extract text to format --------------------------------------------------

    # Get text to highlight from data.frame:
    text2colour = compare %>% 
      
      filter(name == filtername) %>% 
      
      pull(value_current)  
    
    # Get logical indicator to highlight or not from data.frame:
    emphasize = compare %>% 
      
      filter(name == filtername) %>% 
      
      pull(change)


# Format text -------------------------------------------------------------

    # Format the text according to 'emphasize' value:
    if(emphasize == TRUE){
      
      # Apply text style to input text:
      formatted_text = officer::ftext(text2colour, hstyle)
      
    } else {
      
      formatted_text = text2colour
      
    }
    
    # Return coloured text:
    return(formatted_text)

  }

}