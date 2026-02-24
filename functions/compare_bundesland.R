#' Function to compare bundesland values and statements from 2 linelists
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function compares the clean current and previous line lists and 
#' calculates the number of bundesland which are new in the current linelist, 
#' already existed in the previous linelist but have new cases, and for which 
#' there has been no change since the previous linelist.  For each of the three 
#' scenarios a statement summarising the bundeslands by two-letter code and 
#' number of cases is produced.
#'
#' @md
#' 
#' @import dplyr
#' @import stringr
#' 
#' @param current current linelist (clean data) in a data.frame
#' @param previous previous linelist (clean data) in a data.frame
#' 
#' @return list of values and statements for the three scenarios
#'
#' @examples
#' \donttest{
#' # Create list of values and statements comparing bundesland:
#' bundescompare <- compare_bundesland(current = linelist, 
#'                                     previous = linelist_old) 
#' }
#' @export
compare_bundesland <- function(current, previous){
  
  # Bundesland table for current linelist:
  bundesland_ctab = current %>% 
    
    janitor::tabyl(bundesland_lettercode, show_na = FALSE) %>% 
    
    arrange(desc(n)) %>%
    
    select(-percent) %>% 
    
    rename(n_current = n)
  
  # Bundesland table for old linelist:
  bundesland_ptab = previous %>% 
    
    janitor::tabyl(bundesland_lettercode, show_na = FALSE) %>% 
    
    arrange(desc(n)) %>%
    
    select(-percent) %>% 
    
    rename(n_previous = n)
  
  # Merge the two tables:
  bundesland_tabcompare = bundesland_ctab %>% 
    
    left_join(bundesland_ptab) %>% 
    
    mutate(change_type = case_when(
      
      n_previous == 0 & n_current > 0           ~ "new state", 
      n_previous > 0 & n_current != n_previous  ~ "new cases", 
      n_previous > 0 & n_current == n_previous  ~ "no change", 
      n_previous == 0 & n_current == 0          ~ "exclude"
      
    ))
  
  # Calculate number of bundesland which are new:
  newstate_n = bundesland_tabcompare %>% 
    
    filter(change_type == "new state") %>% 
    
    count() %>% 
    
    pull()
  
  # Statement for bundesland which are new:
  newstate_statement = bundesland_tabcompare %>% 
    
    filter(change_type == "new state") %>%
    
    mutate(fscases = paste(n_current, "x", bundesland_lettercode)) %>% 
    
    pull(fscases) %>% 
    
    stringr::str_flatten_comma(last = " und ", na.rm = TRUE)
  
  # Calculate number of existing bundesland with new cases:    
  newcases_n = bundesland_tabcompare %>% 
    
    filter(change_type == "new cases") %>% 
    
    count() %>% 
    
    pull()
  
  # Statement for existing bundesland with new cases:
  newcases_statement = bundesland_tabcompare %>% 
    
    filter(change_type == "new cases") %>%
    
    mutate(fscases = paste(n_current, "x", bundesland_lettercode)) %>% 
    
    pull(fscases) %>% 
    
    stringr::str_flatten_comma(last = " und ", na.rm = TRUE)
  
  # Calculate number of existing bundesland with no change:
  nochange_n = bundesland_tabcompare %>% 
    
    filter(change_type == "no change") %>% 
    
    count() %>% 
    
    pull()
  
  # Statement for bundesland with no change in case numbers:
  nochange_statement = bundesland_tabcompare %>% 
    
    filter(change_type == "no change") %>%
    
    mutate(fscases = paste(n_current, "x", bundesland_lettercode)) %>% 
    
    pull(fscases) %>% 
    
    stringr::str_flatten_comma(last = " und ", na.rm = TRUE)
  
  
  ####################################
  # Return values and statements:
  
  # Compile as a list:
  bundeslist <- list(newstate_n = newstate_n, 
                     newstate_statement = newstate_statement, 
                     newcases_n = newcases_n, 
                     newcases_statement = newcases_statement, 
                     nochange_n = nochange_n, 
                     nochange_statement = nochange_statement)
  
  # Return list:
  return(bundeslist)

}