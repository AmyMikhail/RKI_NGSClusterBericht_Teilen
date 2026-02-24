#' Function to create break labels for incidence map
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function creates break labels for the incidence map. It uses the break
#' method defined in the report parameters (default is fisher) and passes this
#' to the `mapsf::mf_get_breaks()` function. Breaks are defined with `cut` and
#' formatted as sensible text labels (different separator for first break).  
#'
#' @md
#' 
#' @import readr
#' @import dplyr
#' @import forcats
#' @import mapsf
#' 
#' @param x numeric vector of incidence data to create breaks from
#' @param breakmethod method to use to define breaks (inherit from params)
#' 
#' @return Vector of break labels same length and order as input vector
#'
#' @examples
#' \donttest{
#' linelist <- linelist %>% 
#'   mutate(incidence_breaks = ibreak_labeller(x = incidence))
#' }
#' @export
ibreak_labeller <- function(x, breakmethod = params$map_breaks){
  
  # Get breaks for x:
  ibreaks = mapsf::mf_get_breaks(x = x, 
                                 nbreaks = 4, 
                                 breaks = breakmethod) 
  
  # Format breaks for label matching:
  ibreaksf = ibreaks %>% 
    
    format(digits = 3, 
           decimal.mark = ","#, 
           #drop0trailing = TRUE
           )
  
  # Put x in a data.frame:
  df = data.frame(x = x)
  
  # Add columns to data.frame:
  df = df %>% 
    
    # Add column with break points:
    mutate(xbreaks = cut(x = x, 
                         breaks = ibreaks)) %>% 
    
    # Get lower break point:
    mutate(xbreak_lower = as.numeric(sub(
      "\\((.+),.*", 
      "\\1", 
      xbreaks))) %>%
    
    # Get upper break point:
    mutate(xbreak_upper = as.numeric(sub(
      "[^,]*,([^]]*)\\]", 
      "\\1", 
      xbreaks))) %>% 
    
    # Format lower and upper breaks:
    mutate(across(.cols = starts_with("xbreak_"), 
                  .fns = ~ format(x = .x, 
                                  digits = 3, 
                                  decimal.mark = ","#, 
                                  #drop0trailing = TRUE
                                  ))) %>% 
    
    # Add lower breakpoint for lowest incidence value:
    mutate(xbreak_lower = ifelse(x == min(x, na.rm = TRUE), 
                                 yes = min(ibreaksf), 
                                 no = xbreak_lower)) %>% 
    
    # Add upper breakpoint for the lowest incidence value:
    mutate(xbreak_upper = ifelse(x == min(x, na.rm = TRUE),
                                 yes = ibreaksf[2], 
                                 no = xbreak_upper)) %>% 
    
    # Create pretty breaks label:
    mutate(xbreak_labels = case_when(
      
      # Identify minimum incidence breaks:
      xbreak_lower == min(ibreaksf) 
      ~ paste0("\u2265 ", xbreak_lower, " & \u2264 ", xbreak_upper),
      
      # Replace NAs:
      is.na(x) 
      ~ "Keine gemeldeten Fälle", 
      
      # Set label for all other sets of break points:
      TRUE 
      ~ paste0("> ", xbreak_lower, " & \u2264 ", xbreak_upper)
      
    )) %>% 
    
    # Convert to ordered factor:
    mutate(xbreak_flabels = factor(
      x = xbreak_labels, 
      levels = unique(xbreak_labels)
    )) 
  
  # Extract break labels:
  ibreak_labels = df %>% 
    
    pull(xbreak_flabels)
  
  # Return break labels:
  return(ibreak_labels)
  
}