#' Function to convert table of numeric values to a heatmap
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function will convert a table (data.frame) of numeric values to a 
#' heatmap table, where the values are conditionally highlighted with 
#' increasingly dark colours as the values increase.  The colour of the text 
#' automatically changes to white for darker colours to maintain contrast. The
#' table is then converted to a flextable, where some additional formatting is 
#' applied.  All the numeric columns to be highlighted must be in a block, but
#' multiple columns can be used as row labels (they will be identified as text).
#'
#' @md
#'
#' @import dplyr
#' @import ztable
#' @import flextable
#' 
#' @param data data.frame or matrix of numbers to convert to a heat-table
#' 
#' @return formatted flextable with graduated light to dark red highlighting
#'
#' @examples
#' # Create cross-tab of example data:
#' cases <- data.frame(Country = c("Germany", "Spain", "Austria"), 
#'                     Fruit = c("Apple", "Pear", "Strawberry"), 
#'                     Jan = c(40, 12, 15), 
#'                     Feb = c(10, 4, 3))
#' 
#' # Apply function to convert to heatmap table:
#' caseshm <- heatmaptable(cases)
#' 
#' # View the result:
#' caseshm
#'
#' @export
heatmaptable <- function(data){
  
  # Define vector of numeric column names:
  numcols = names(dplyr::select_if(data,is.numeric))
  
  # Define colour palatte:
  mypal = gradientColor(low = "white", high = "darkred")
  
  # Define data:
  dft = data %>% 
    
    # Make sure the data is a data.frame (others won't work):
    as.data.frame() %>% 
    
    # Convert to a ztable specifying formatting options:
    ztable(digits = 0, 
           include.rownames = TRUE, 
           tablewidth = 10) %>%
    
    # Convert the ztable object to a heatmap using default settings:
    makeHeatmap(mycolor = mypal) %>%
    
    # Convert to flextable and tidy up aesthetics:
    ztable2flextable() %>% 
    
    # Remove extra row labels:
    void(j = 1, part = "all") %>%
    
    # Align all text columns to be left-justified:
    align_text_col(align = "left", header = TRUE, footer = TRUE) %>% 
    
    # Align all numeric columns to be centre-justified:
    align(j = numcols, align = "center", part = "all") %>% 
    
    # Make the header bold:
    bold(bold = TRUE, part = "header") %>% 
    
    # Auto-adjust column widths to fit content:
    autofit()
  
  # Return the heatmap table:
  return(dft)
  
}