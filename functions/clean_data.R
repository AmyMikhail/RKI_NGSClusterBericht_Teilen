#' @include get_yearweek.R
#' @include get_yearmonth.R
NULL

#' Function to clean line list data
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function cleans imported line list data and adds derived variables 
#' (such as age categories) needed for further analysis.  It depends on the 
#' data dictionary and cleaned geocodes for county / district, which must 
#' already be imported before this function is run.  Two parameters are also
#' inherited from the R markdown document: lag_casedate and lag_labdate. 
#'
#' @md
#' 
#' @import dplyr
#' @import janitor
#' @import lubridate
#' @import epikit
#' 
#' @param raw_data Line list to clean (data.frame)
#' @param lag_casedate Lag in weeks to estimate onset from case report date
#' @param lag_labdate Lag in weeks to estimate onset from sample receipt date
#' 
#' @return Cleaned line list in a data.frame
#'
#' @examples
#' \donttest{
#' # Clean line list of raw data:
#' linelist_clean <- clean_data(raw_data = linelist_raw, 
#'                              dictionary = dictionary, 
#'                              geocodes = geocodes)
#' }
#' @export
clean_data <- function(raw_data, 
                       lag_casedate = params$lag_casedate, 
                       lag_labdate = params$lag_labdate){
  
  ######################################################################
  # CREATE DATA DICTIONARY LOOKUP:
  
  # Convert the data dictionary into a lookup table:
  varlookup = setNames(dictionary$varname_data, dictionary$varname_code)
  
  ######################################################################
  # CREATE LIST OF ESSENTIAL VARIABLES:
  
  # Extract list of essential variables from dictionary:
  vars2keep = dictionary %>% 
    
    filter(var_in_script == TRUE) %>% 
    
    select(varname_code) %>% 
    
    pull()
  
  ######################################################################
  # CLEAN LINE LIST:
  
  # Clean the raw line list:
  linelist_clean = raw_data %>% 
    
    # Remove spaces and non-alpha-numeric characters from column names:
    janitor::clean_names() %>% 
    
    # Assign short variable names from the data dictionary lookup table:
    rename(any_of(varlookup)) %>% 
    
    # Select only columns essential for this report:
    select(all_of(vars2keep)) %>% 
    
    # Convert all date columns to poxict:
    mutate(across(.cols = contains("date"), .fns = ~ as.POSIXct(.x))) %>% 
    
    # Replace 'not ascertained' with NA across whole data set:
    mutate(across(where(is.character), 
                  function(x) ifelse(x %in%  c("-nicht erhoben-", 
                                               "-nicht ermittelbar-"), 
                                     NA_character_, 
                                     x)
                  )) %>% 
    
    # Convert all character columns to sentence case for consistency:
    #mutate(across(where(is.character), stringr::str_to_sentence)) %>% 
    
    ###### Consolidate missing isolates & case notifications: #######
  
  # Consolidate case ID (survnet ID or NRZ ID for isolates with no case info):
  mutate(caseid = ifelse(test = grepl(pattern = "kein", 
                                      x = case_survnetid, 
                                      ignore.case = TRUE) == TRUE, 
                         yes = paste0("CID_", isolate_nrzid), 
                         no = paste0("CID_", case_survnetid))) %>% 
    
    # Create isolate birth 'date' using year, month and 01 as the date:
    mutate(isolate_birthdate = 
             as.POSIXct(
               lubridate::make_date(year = isolate_birthyear, 
                                    month = isolate_birthmonth,
                                    day = 1L)
             )) %>% 
    
    # Calculate isolate birth age using birth 'date' and isolate submit date:
    mutate(isolate_birthage = case_when(
      
      !is.na(isolate_submitdate) 
      ~ as.numeric(round(x = ((isolate_submitdate - isolate_birthdate)/365), 
                         digits = 0)),
      
      is.na(isolate_submitdate) & !is.na(isolate_receiptdate) 
      ~ as.numeric(round(x = ((isolate_receiptdate - isolate_birthdate)/365), 
                         digits = 0)),
      
      TRUE ~ NA)) %>% 
    
    # Consolidate age (survnet age or calculate for isolates with no case info):
    mutate(age_final = coalesce(case_calculatedage, isolate_birthage)) %>% 
    
    # Add adult / child designation:
    mutate(age_group = case_when(
      !is.na(age_final) & age_final >= 18 ~ "adult", 
      !is.na(age_final) & age_final < 18  ~ "child", 
      TRUE                                ~ NA_character_)) %>% 
    
    # Add age categories:
    mutate(age_cat = epikit::age_categories(x = age_final, 
                                            breakers = c(0, 1, 5, 10, 15,
                                                         20, 25, 30, 40, 
                                                         50, 60, 70, 80))) %>% 
    
    # Change the label of the lowest age cat from 0-0 to <1:
    mutate(age_cat = fct_recode(age_cat, "<1" = "0-0")) %>% 

    # Consolidate sex (survnet sex or NRZ sex for isolates with no case info):
    mutate(sex_final = coalesce(case_sex, isolate_sex)) %>% 
    
    # Convert case definition to sentence case:
    mutate(case_definition = stringr::str_to_sentence(case_definition)) %>%
    
    # Convert case definition to a factor:
    mutate(case_definition = factor(case_definition, 
                                    levels = c("Bestätigter", 
                                               "Wahrscheinlicher", 
                                               "Möglicher"))) %>% 
    
    # Consolidate federal state (survnet or NRZ for isolates with no case info):
    mutate(bundesland_final = coalesce(case_reportfedstate, 
                                       isolate_fedstate)) %>% 
    
    # Add bundesland code column (join on bundesland_final and bundesland_name):
    left_join(pop_bundesland %>% select(bundesland_name, 
                                        bundesland_lettercode, 
                                        bundesland_numcode), 
              by = join_by(bundesland_final == bundesland_name)) %>% 
    
    # Consolidate county (survnet or NRZ for isolates with no case info):
    mutate(kreise_final = coalesce(case_reportcounty, isolate_county)) %>% 
    
    # Add county_code column (join on county_final which is residence county):
    left_join(pop_berlin %>% select(area_name, 
                                    area_code), 
              by = join_by(kreise_final == area_name)) %>%
    
    # Convert bundesland lettercode to a factor with all 16 codes as levels:
    mutate(bundesland_lettercode = factor(
      bundesland_lettercode, 
      levels = unique(pop_berlin$bundesland_lettercode))) %>% 
    
    # Also remove county prefixes 'LK' and 'SK' as they are not in shapefile:
    mutate(kreise_final = gsub(pattern = "LK |SK ",
                               replacement = "",
                               x = kreise_final)) %>%
    
    # Create Berlin district residency column:
    mutate(berlin_district_name = ifelse(
      test = grepl(pattern = "^Berlin ", x = kreise_final), 
      yes = gsub(pattern = "^Berlin ", replacement = "", x = kreise_final), 
      no = NA_character_)) %>% 
    
    # Create Berlin district residency code column:
    mutate(berlin_district_code = ifelse(
      test = grepl(pattern = "^Berlin ", x = kreise_final), 
      yes = area_code, 
      no = NA_character_)) %>% 
    
    # Update county_final column to remove Berlin district names:
    mutate(kreise_final = ifelse(
      test = grepl(pattern = "^Berlin ", x = kreise_final), 
      yes = "Berlin", 
      no = kreise_final
    )) %>% 
    
    # Update area code column for Berlin:
    mutate(area_code = ifelse(
      test = kreise_final == "Berlin", 
      yes = "11000", 
      no = area_code
    )) %>% 
    
    # Rename area code as county code:
    rename(kreise_code = area_code) %>% 
    
    # Add Bundesland exposure column from lookup (join on case_exposurecounty):
    left_join(pop_berlin %>% select(-area_pop), 
              by = join_by(case_exposurecounty == area_name), 
              suffix = c("", "_exposure")) %>% 
    
    # Rename area code again:
    rename(area_code_exposure = area_code) %>% 
    
    # Create consolidated exposure location column:
    mutate(exposelocation_final = case_when(
      
      !is.na(bundesland_lettercode_exposure) ~ bundesland_lettercode_exposure,
      
      is.na(bundesland_lettercode_exposure) 
      & !is.na(case_exposurenation) 
      & case_exposurenation != "Deutschland" ~ "Ausland", 
      
      TRUE ~ NA_character_
      
    )) %>% 
    
    # Create final serovar column from NRZ (lab) serovars:
    mutate(serovar_final = isolate_serovar) %>% 
    
    # Add spaces after . if missing to consolidate serovar names:
    mutate(serovar_final = ifelse(
      
      # \\s is the regular expression for a space (double-escaped)
      test = grepl(pattern = "\\s",                 
                   x = serovar_final, 
                   ignore.case = TRUE) == FALSE,
      
      # \\. looks for a '.' (double escaped otherwise . = wildcard)
      yes = gsub(pattern = "\\.",                   
                 replacement = "\\. ", 
                 x = serovar_final), 
      no = serovar_final)) %>% 
    
    # Remove S. prefix from serovar_final:
    mutate(serovar_final = gsub(pattern = "^S. ", 
                                replacement = "", 
                                x = serovar_final)) %>% 
    
    # Convert nicth erhoben to NA:
    mutate(serovar_final = na_if(x = serovar_final, 
                                 y = "-nicht erhoben-")) %>% 
    
    # Create new column for serogroup:
    mutate(serogroup_final = ifelse(
      
      # Select serovars that have the word 'gruppe' in them:
      test = grepl(pattern = "Gruppe ", 
                   x = serovar_final, 
                   ignore.case = TRUE), 
      
      # If yes, use the serovar:
      yes = gsub(pattern = "^Salmonella der Gruppe ", 
                 replacement = "", 
                 x = serovar_final), 
      
      # If no, make NA:
      no = NA_character_)) %>% 
    
    # Now update serovar so that it only contains serovars:
    mutate(serovar_final = ifelse(test = !is.na(serogroup_final), 
                                  yes = NA_character_, 
                                  no = serovar_final)) %>% 
    
    # Now use Kauffmann-White scheme to update missing serogroups:
    left_join(kw_lookup, 
              join_by(serovar_final == serovar_kw)) %>% 
    
    # Then use the joined data to tidy up serogroup_final:
    mutate(serogroup_final = coalesce(serogroup_final, serogroup_kw)) %>% 
    
    # Consolidate dates to use for epicurve:
    mutate(epicurve_dates = case_when(
      
      # First try symptom onset (as is):
      !is.na(case_onsetdate)        ~ case_onsetdate,
      
      # If missing, try report date - 1 week to account for lag:
      is.na(case_onsetdate) 
      & !is.na(case_reportdate)     ~ 
        
        # Estimate symptom onset date from case notification date:
        case_reportdate - lubridate::weeks(lag_casedate),
      
      # If missing, try lab sample receipt date - 1 week to account for lag:
      is.na(case_onsetdate) 
      & is.na(case_reportdate) 
      & !is.na(isolate_receiptdate) ~ 
        
        # Estimate symptom onset date from sample receipt date:
        isolate_receiptdate - lubridate::weeks(lag_labdate), 
      
      # If all these are missing, convert to NA:
      TRUE                          ~ NA_POSIXct_
      
    )) %>% 
    
    # Convert dates from posixct (incorrect with 0s for time) to date:
    mutate(epicurve_dates = as.Date(epicurve_dates)) %>% 
    
    # Create epicurve year week from epicurve dates:
    mutate(epicurve_yearweek = get_yearweek(epicurve_dates)) %>% 
    
    # Create epicurve year month from epicurve dates:
    mutate(epicurve_yearmonth = get_yearmonth(epicurve_dates)) %>% 
    
    # Create epcurve year quarter from epicurve dates:
    mutate(epicurve_yearquarter = lubridate::quarter(epicurve_dates, 
                                                     with_year = TRUE)) %>% 
    
    # Update hospitalised reason column to make unknown NA:
    mutate(case_hospitalisedreason = 
             na_if(x = case_hospitalisedreason, 
                   y = "Hospitalisiert, Ursache ist unbekannt")) %>% 
    
    # Create consolidated hospitalisation column:
    mutate(hosp_final = case_when(
      
      # Hospitalised due to Salmonellosis:
      case_hospitalisedstatus == "Ja"
      & case_hospitalisedreason == "Hospitalisiert aufgrund der gemeldeten Krankheit"
      ~ "Hospitalisierung aufgrund der Salmonellose", 
      
      # Hospitalised due to other cause:
      case_hospitalisedstatus == "Ja"
      & grepl(pattern = "einer anderen Ursache", 
              x = case_hospitalisedreason) == TRUE 
      ~ "Hospitalisierung aufgrund anderer Ursachen", 
      
      # Not hospitalised:
      case_hospitalisedstatus == "Nein"
      ~ "Nicht hospitalisiert",
      
      # Hospitalisation status or reason unknown:
      TRUE
      ~ NA_character_

    )) %>% 
    
    # Reorder levels for hosp_final:
    mutate(hosp_final = factor(
      hosp_final, 
      ordered = TRUE,
      levels = c("Hospitalisierung aufgrund der Salmonellose", 
                 "Hospitalisierung aufgrund anderer Ursachen", 
                 "Nicht hospitalisiert"))) %>% 
    
    # Create short labels for hospital graphs:
    mutate(hosp_labels = case_when(
      
      hosp_final == "Hospitalisierung aufgrund der Salmonellose" 
      ~ "Salmonellose", 
      
      hosp_final == "Hospitalisierung aufgrund anderer Ursachen" 
      ~ "Andere Ursache", 
      
      hosp_final == "Nicht hospitalisiert" 
      ~ "Nicht hospitalisiert", 
      
      TRUE ~ NA_character_
      
    )) %>% 
    
    # Reorder short hospital labels and convert to ordered factor:
    mutate(hosp_labels = factor(
      hosp_labels, 
      ordered = TRUE,
      levels = c("Salmonellose", 
                 "Andere Ursache", 
                 "Nicht hospitalisiert"))) %>% 
    
    # Consolidate final death column:
    mutate(death_final = case_when(
      
      # Death due to salmonellosis:
      case_deathstatus == "Ja" 
      & case_deathcause == "an der gemeldeten Krankheit"
      ~ "Todesfälle aufgrund von Salmonellose", 
      
      # Death due to other cause:
      case_deathstatus == "Ja"
      & case_deathcause == "aufgrund anderer Ursache"
      ~ "Todesfälle durch andere Ursachen", 
      
      # Did not die:
      case_deathstatus == "Nein"
      ~ "Nicht gestorben", 
      
      # Death status unknown:
      TRUE
      ~ NA_character_
      
    )) %>% 
    
    # Reorder levels for death_final:
    mutate(death_final = factor(
      death_final, 
      ordered = TRUE, 
      levels = c("Todesfälle aufgrund von Salmonellose", 
                 "Todesfälle durch andere Ursachen", 
                 "Nicht gestorben")
    )) %>% 
    
    # Create severity column based on hosp and death status:
    mutate(severity = case_when(
      
      # If case died of salmonellosis:
      death_final == "Todesfälle aufgrund von Salmonellose" 
      ~ "Gestorben (Salmonellose)", 
      
      # If case died of other causes:
      death_final == "Todesfälle durch andere Ursachen" 
      ~ "Gestorben (andere Ursache)", 
      
      # If case hospitalised due to salmonella but not dead:
      death_final == "Nicht gestorben" 
      & hosp_final == "Hospitalisierung aufgrund der Salmonellose" 
      ~ "Krankenhausaufenthalt (Salmonellose)",
      
      # If case hospitalised due to other cause but not dead:
      death_final == "Nicht gestorben" 
      & hosp_final == "Hospitalisierung aufgrund anderer Ursachen" 
      ~ "Krankenhausaufenthalt (andere Ursache)",
      
      # If case is not hospitalised and not dead:
      death_final == "Nicht gestorben"
      & hosp_final == "Nicht hospitalisiert" 
      ~ "Nicht hospitalisiert", 
      
      # If anything else - Unknown:
      TRUE ~ "Status unbekannt"
      
    )) %>% 
    
    # Convert severity to an ordered factor:
    mutate(severity = factor(severity, 
                             levels = c("Nicht hospitalisiert", 
                                        "Krankenhausaufenthalt (andere Ursache)", 
                                        "Krankenhausaufenthalt (Salmonellose)", 
                                        "Gestorben (andere Ursache)", 
                                        "Gestorben (Salmonellose)", 
                                        "Status unbekannt"), 
                             ordered = TRUE)) %>% 
    
    # Create demographic statements for dead cases:
    mutate(death_demographic = case_when(
      
      # if death is female child:
      case_deathstatus == "Ja"
      & sex_final == "weiblich" 
      & age_group == "child"
      ~ paste0("ein ", 
               age_final, 
               "-jähriges Mädchen aus ", 
               bundesland_lettercode), 
      
      # If death is male child:
      case_deathstatus == "Ja"
      & sex_final == "männlich" 
      & age_group == "child"
      ~ paste0("ein ", 
               age_final, 
               " Jahre alter Junge aus ", 
               bundesland_lettercode), 
      
      # If death is female adult:
      case_deathstatus == "Ja"
      & sex_final == "weiblich" 
      & age_group == "adult"
      ~ paste0("eine ", 
               age_final, 
               " Jahre alte Frau aus ", 
               bundesland_lettercode), 
      
      # If death is male adult:
      case_deathstatus == "Ja"
      & sex_final == "männlich" 
      & age_group == "adult"
      ~ paste0("ein ", 
               age_final, 
               "-jähriger Mann aus ", 
               bundesland_lettercode), 
      
      # If did not die or death status unknown:
      TRUE ~ NA_character_

    ))
  

  ######################################################################
  # RETURN CLEANED LINE LIST:
  
  return(linelist_clean)

}