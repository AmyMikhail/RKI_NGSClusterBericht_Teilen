#' @include get_yearweek.R
#' @include get_yearmonth.R
#' @include print_dateunit.R
NULL

#' Function to extract summary figures and statements from a line list
#'
#' @author Amy Mikhail, \email{amy.mikhail@@gmail.com}
#'
#' @description
#' This function takes clean line list data as input and returns a table of 
#' named figures and statements (character strings) that can be inserted into
#' R markdown executive summary text as inline code. The easiest way to insert
#' a figure or statement from the table is to use its placeholder name as a 
#' character string (e.g. "n_cases") inside a call to the colourtext() function.
#' The suffix 'current' can be used if extracting figures from the current line
#' list, otherwise use 'previous' if extracting figures from a previous line 
#' list for comparison.  The suffix is appended to the name of the value column.
#' This makes it easier to merge the figures extracted from two line lists later
#' on and compare the values.
#'
#' @md
#' 
#' @import dplyr
#' @import lubridate
#' @import stringr
#' @import flextable
#' 
#' @param data Cleaned line list data to extract summary figures from
#' @param suffix One of 'current' or 'previous' to indicate which line list
#' 
#' @return Data.frame of placeholder names and figures/statements
#'
#' @examples
#' \donttest{
#' # Calculate and extract summary figures from current line list:
#' sumfigs <- execsum(data = linelist_new, suffix = "current") 
#' }
#' @export
execsum <- function(data, suffix = c("current", "previous")){
  

# 02. Case definitions ----------------------------------------------------

  ### --- a. latest_update
  ### --- b. n_cases
  ### --- c. n_confirmed
  ### --- d. n_sequenced
  ### --- e. n_epilinked
  ### --- f. n_probable
  ### --- g. n_prob_seqpending
  ### --- h. n_possible
  ### --- i. n_seqpending
  ### --- j. serovars
  ### --- k. serogroups
  ### --- l. n_poss_seqpending
  
  
  # a. Format latest_update
  latest_update = format(latest_update, format = "%d. %B %Y")
  
  # b. n_cases (calculate total number of cases)
  n_cases = nrow(data)
  
  # c. n_confirmed (calculate number of confirmed cases)
  n_confirmed = data %>% 
    
    filter(case_definition == "Bestätigter") %>% 
    
    count() %>% 
    
    pull()
  
  # d. n_sequenced (calculate the number of confirmed cases with sequencing)
  n_sequenced = data %>% 
    
    filter(case_definition == "Bestätigter" 
           & isolate_ngsstatus == "fertig") %>% 
    
    count() %>% 
    
    pull()
  
  # e. n_epilinked (calculate the number of cases confirmed by epilink)
  n_epilinked = data %>% 
    
    filter(case_definition == "Bestätigter" 
           & !is.na(case_outbreaklink) 
           & is.na(isolate_ngsclusterid)) %>% 
    
    count() %>% 
    
    pull()
  
  # f. n_probable (calculate the number of probable cases)
  n_probable = data %>% 
    
    filter(case_definition == "Wahrscheinlicher") %>% 
    
    count() %>% 
    
    pull()
  
  # g. n_prob_seqpending (calculate probable cases pending sequencing)
  n_prob_seqpending = data %>% 
    
    filter(case_definition == "Wahrscheinlicher" 
           & isolate_ngsstatus == "vorgemerkt") %>% 
    
    count() %>% 
    
    pull()
  
  # h. n_possible (calculate number of possible cases)
  n_possible = data %>% 
    
    filter(case_definition == "Möglicher") %>% 
    
    count() %>% 
    
    pull()
  
  # i. n_seqpending (calculate total number of isolates pending sequencing)
  n_seqpending <- data %>% 
    
    filter(isolate_ngsstatus == "vorgemerkt") %>% 
    
    count() %>% 
    
    pull()
  
  # j. serovars (create statement listing serovars included in the outbreak)
  
  # Calculate number of serovars:
  n_serovars = data %>% 
    
    drop_na(serovar_final) %>% 
    
    distinct(serovar_final) %>% 
    
    pull(serovar_final) %>% 
    
    length()
  
  # Create base statement:
  serovars = data %>% 
    
    distinct(serovar_final) %>% 
    
    stringr::str_flatten_comma(last = " und ", na.rm = TRUE)
  
  # Add conditional grammar text:
  if(n_serovars == 1){
    
    serovars = paste0("dem *Salmonella enterica* Serovar ", serovars)
    
  } else if(n_serovars > 1){
    
    serovars = paste0("den *Salmonella enterica*-Serovaren ", serovars)
    
  }
  
  # k. serogroups (create statement listing serogroups included in the outbreak)
  
  # Calculate number of serogroups:
  n_serogroups = data %>% 
    
    drop_na(serogroup_final) %>% 
    
    distinct(serogroup_final) %>% 
    
    pull(serogroup_final) %>% 
    
    length()
  
  # Create base statement for serogroups:
  serogroups = data %>% 
    
    distinct(serogroup_final) %>% 
    
    arrange(serogroup_final) %>% 
    
    stringr::str_flatten_comma(last = " und ", na.rm = TRUE)
  
  # Add conditional grammar text:
  if(n_serogroups == 1){
    
    serogroups = paste0("Serogruppe ", serogroups)
    
  } else if(n_serogroups > 1){
    
    serogroups = paste0("Serogruppen ", serogroups)
    
  }
  
  # l. n_poss_seqpending (calculate possible cases pending sequencing)
  n_poss_seqpending = data %>% 
    
    filter(case_definition == "Möglicher" 
           & isolate_ngsstatus == "vorgemerkt") %>% 
    
    count() %>% 
    
    pull()
  


# 03. Temporal distribution -----------------------------------------------

  ### --- a. n_totalweeks
  ### --- b. n_activeweeks
  ### --- c. n_activeweeks_prop
  ### --- d. median_cpw
  ### --- e. min_epidate
  ### --- f. min_epiweek
  ### --- g. n_50percentcases
  ### --- h. median_week
  ### --- i. max_cpw
  ### --- j. max_cpw_week
  ### --- k. n_latestcases
  ### --- l. max_epiweek
  ### --- m. max_epidate
  ### --- n. max_reportdate
  ### --- o. max_onsetdate
  
  
  # Create table of case numbers by year-week for whole outbreak period:
  weekly_counts = data %>%
    
    drop_na(epicurve_dates) %>% 
    
    mutate(epicurve_date2 = as.Date(epicurve_dates)) %>% 
    
    mutate(week_date = lubridate::floor_date(epicurve_date2, unit = "week")) %>%
    
    count(week_date, name = "cases") %>% 
    
    tidyr::complete(
      
      week_date = seq.Date(
        
        from = min(week_date), 
        to = max(week_date),
        by = "week"), 
      
      fill = list(cases = 0)) %>% 
    
    mutate(epi_yw = get_yearweek(week_date)) %>% 
    
    mutate(epi_ym = get_yearmonth(week_date))
  
  
  # Create long form of table for stats:
  wc_long = weekly_counts %>% 
    
    uncount(cases) %>% 
    
    mutate(cases = 1)
  
  
  # a. n_totalweeks (total duration of outbreak to date in weeks):
  n_totalweeks = nrow(weekly_counts)
  
  # b. n_activeweeks (numer of weeks with at least one case):
  n_activeweeks = weekly_counts %>% 
    
    filter(cases > 0) %>% 
    
    count() %>% 
    
    pull()
  
  # c. n_activeweeks_prop (percentage of wweeks with at least 1 case)
  n_activeweeks_prop = paste0(
    round((n_activeweeks/n_totalweeks) * 100, digits = 0), 
    "%"
    )
  
  # d. median_cpw (calculate median number of cases per week excluding 0s)
  median_cpw = weekly_counts %>% 
    
    filter(cases > 0) %>% 
    
    pull(cases) %>% 
    
    median(na.rm = TRUE) 
  
  # e. min_epidate (calculate earliest epicurve date)
  min_epidate = data %>% 
    
    pull(epicurve_dates) %>% 
    
    min(na.rm = TRUE) %>% 
    
    format(format = "%d. %B %Y")
  
  # f. min_epiweek (calculate earliest epicurve year-week)
  min_epiweek = data %>% 
    
    pull(epicurve_yearweek) %>% 
    
    min(na.rm = TRUE) %>% 
    
    print_dateunit(aggtype = "week")
  
  # g. n_50percentcases (calculate number of cases at median of total weeks)
  n_50percentcases = weekly_counts %>% 
    
    filter(week_date <= median(week_date, na.rm = TRUE)) %>% 
    
    pull(cases) %>% 
    
    sum(na.rm = TRUE)
  
  # h. median_week (calculate median week over whole outbreak period)
  median_week = weekly_counts %>% 
    
    pull(week_date) %>% 
    
    median(na.rm = TRUE) %>% 
    
    get_yearweek() %>% 
    
    print_dateunit(aggtype = "week")
  
  # i. max_cpw (calculate the maximum number of cases per week)
  max_cpw = weekly_counts %>% 
    
    pull(cases) %>% 
    
    max(na.rm = TRUE)
  
  # j. max_cpw_week (calculate week on which max number of cases were recorded)
  max_cpw_week = weekly_counts %>% 
    
    filter(cases == max(cases, na.rm = TRUE)) %>% 
    
    pull(epi_yw) %>% 
    
    max(na.rm = TRUE) %>% 
    
    print_dateunit(aggtype = "week")
  
  # k. n_latestcases (calculate number of cases in latest week)
  n_latestcases = weekly_counts %>% 
    
    filter(epi_yw == max(epi_yw, na.rm = TRUE)) %>% 
    
    pull(cases)
  
  # l. max_epiweek (calculate the latest year-week with cases)
  max_epiweek = weekly_counts %>% 
    
    pull(epi_yw) %>% 
    
    max(na.rm = TRUE) %>% 
    
    print_dateunit(aggtype = "week")
  
  # m. max_epidate (calculate latest epicurve_date for most recent case)
  max_epidate = data %>% 
    
    pull(epicurve_dates) %>% 
    
    max(na.rm = TRUE) %>% 
    
    format(format = "%d. %B %Y")
  
  # n. max_reportdate (calculate latest report date from survnet):
  max_reportdate = data %>% 
    
    pull(case_reportdate) %>% 
    
    max(na.rm = TRUE) %>% 
    
    format(format = "%d. %B %Y")
  
  # o. max_onsetdate (calculate latest onset date from survnet):
  max_onsetdate = data %>% 
    
    pull(case_onsetdate) %>% 
    
    max(na.rm = TRUE) %>% 
    
    format(format = "%d. %B %Y")
  

# 04. Geographic distribution ---------------------------------------------

  
  ### --- a. n_bundesland
  ### --- b. statement_bundesland
  
  
  # a. n_fedstates (count total number of federal states with cases)
  n_bundesland = data %>% 
    
    filter(!is.na(bundesland_lettercode)) %>% 
    
    distinct(bundesland_lettercode) %>% 
    
    count() %>% 
    
    pull()
  
  # b. statement with numbers of cases per federal state:
  statement_bundesland = data %>% 
    
    filter(!is.na(bundesland_lettercode)) %>% 
    
    janitor::tabyl(bundesland_lettercode) %>% 
    
    filter(n != 0) %>% 
    
    mutate(fscases = paste(n, "x", bundesland_lettercode)) %>% 
    
    arrange(desc(n)) %>% 
    
    pull(fscases) %>% 
    
    stringr::str_flatten_comma(last = " und ", na.rm = TRUE)
  

# 05. Case demographics ---------------------------------------------------


  ### 05.1 SEX ------------------------------------------------------------
  ### --- a. n_female
  ### --- b. n_male
  ### --- c. statement_sexratio
  
  # a. n_female (number of female cases):
  n_female = data %>% 
    
    filter(sex_final == "weiblich") %>% 
    
    count() %>% 
    
    pull()
  
  # b. n_male (number of female cases):
  n_male = data %>% 
    
    filter(sex_final == "männlich") %>% 
    
    count() %>% 
    
    pull()
  
  # c. Statement describing predominant sex:
  
  # Get total number with a value for sex:
  total_sex = data %>% 
    
    drop_na(sex_final) %>% 
    
    nrow()
  
  # Calculate proportion female:
  prop_female = n_female/total_sex
  
  # Calculate proportion male:
  prop_male = n_male/total_sex
  
  # Create the sex statements:
  
  if(prop_female > 0.65){
    
    # Majority female:
    statement_sexratio = "Die Fälle sind überwiegend weiblich"
    
  } else if(prop_male > 0.65){
    
    # Majority male:
    statement_sexratio = "Die Fälle sind überwiegend männlich"
    
  } else {
    
    # Mixed sex distribution:
    statement_sexratio = "Beide Geschlechter sind ungefähr gleich häufig betroffen"
    
  }
  
  
  ### 05.2 AGE ------------------------------------------------------------
  ### --- a. statement_adultchild
  ### --- b. median_age
  ### --- c. range_age
  ### --- d. iqr_age
  
  # a. Statement on predominance of adults or children
  
  # Calculate total number of adults aged 18 and older:
  n_adult = data %>% 
    
    filter(age_group == "adult") %>% 
    
    count() %>% 
    
    pull()  
  
  # Calculate total number of children < 18:
  n_child = data %>% 
    
    filter(age_group == "child") %>% 
    
    count() %>% 
    
    pull()  
  
  # Calculate total with age data:
  total_age = data %>% 
    
    drop_na(age_group) %>% 
    
    nrow()
  
  # Calculate proportion adult:
  prop_adult = n_adult/total_age
  
  # Calculate proportion child:
  prop_child = n_child/total_age
  
  # Create adult / child statements
  if(prop_adult >= 0.55){
    
    # Majority adults:
    statement_adultchild = "Die Mehrheit der Betroffenen sind Erwachsene"
    
  } else if(prop_child >= 0.55){
    
    # Majority children:
    statement_adultchild = "Die Mehrheit der Betroffenen sind Kinder"
    
  } else {
    
    # Mixed adults and children:
    statement_adultchild = "Sowohl Kinder als auch Erwachsene sind betroffen"
    
  }
  
  # Get quantiles:
  agequant = data %>% 
    
    drop_na(age_final) %>% 
    
    pull(age_final) %>% 
    
    quantile() %>% 
    
    unname() %>% 
    
    round(digits = 0)
  
  # b. Median age
  median_age = agequant[3]
  
  # c. Age range
  range_age = paste(agequant[1], "-", agequant[5])
  
  # d. Interquartile range for age:
  iqr_age = paste(agequant[2], "-", agequant[4])
  
  
  
  ### 05.3. HOSPITALISATION ----------------------------------------------- 
  ### --- a. n_hosp_info
  ### --- b. n_hosp_salmonella
  ### --- c. n_hosp_other
  
  # a. Complete hospital information is available for n cases:
  n_hosp_info = data %>% 
    
    filter(!is.na(hosp_final)) %>% 
    
    count() %>% 
    
    pull()
  
  # b. Number of cases hospitalised due to their Salmonella infection:
  n_hosp_salmonella = data %>% 
    
    filter(hosp_final == "Hospitalisierung aufgrund der Salmonellose") %>% 
    
    count() %>% 
    
    pull()
  
  # c. Number of cases hospitalised due to other causes:
  n_hosp_other = data %>% 
    
    filter(hosp_final == "Hospitalisierung aufgrund anderer Ursachen") %>% 
    
    count() %>% 
    
    pull()
  
  
  ### 05.4 Deaths ---------------------------------------------------------
  
  ### --- a. n_deaths_salmonella
  ### --- b. statement_deaths_salm
  ### --- c. n_deaths_other
  ### --- d. statement_deaths_other
  
  # a. Number of cases who died due to their Salmonella infection:
  n_deaths_salmonella = data %>% 
    
    filter(death_final == "Todesfälle aufgrund von Salmonellose") %>% 
    
    count() %>% 
    
    pull()
  
  # b. Case demographic statements for deaths due to Salmonella:
  statement_deaths_salmonella = data %>% 
    
    filter(death_final == "Todesfälle aufgrund von Salmonellose") %>%
    
    pull(death_demographic) %>% 
    
    stringr::str_flatten_comma(last = " und ", na.rm = TRUE)
  
  # c. Number of cases who died due to other causes:
  n_deaths_other = data %>% 
    
    filter(death_final == "Todesfälle durch andere Ursachen") %>% 
    
    count() %>% 
    
    pull()
  
  # d. Case demographic statements for deaths due to other causes:
  statement_deaths_other = data %>% 
    
    filter(death_final == "Todesfälle durch andere Ursachen") %>%
    
    pull(death_demographic) %>% 
    
    stringr::str_flatten_comma(last = " und ", na.rm = TRUE)
  
  

# Create table of placeholders and calculated values ----------------------

  df = data.frame(
    
    # 02. Case definitions:
    latest_update, 
    n_cases, 
    n_confirmed, 
    n_sequenced, 
    n_epilinked, 
    n_probable, 
    n_prob_seqpending, 
    n_possible, 
    n_seqpending,
    serovars, 
    serogroups, 
    n_poss_seqpending,
    
    # 03. Temporal distribution:
    n_totalweeks, 
    n_activeweeks, 
    n_activeweeks_prop, 
    median_cpw, 
    min_epidate, 
    min_epiweek, 
    n_50percentcases, 
    median_week, 
    max_cpw, 
    max_cpw_week, 
    n_latestcases, 
    max_epiweek, 
    max_epidate, 
    max_reportdate,
    max_onsetdate,
    
    # 04. Geographic distribution:
    n_bundesland,
    statement_bundesland, 
    
    # 05.1 Case demographics - sex
    n_female, 
    n_male, 
    statement_sexratio, 
    
    # 05.2 Case demographics - age
    statement_adultchild, 
    median_age, 
    range_age, 
    iqr_age, 
    
    # 05.3 Case demographics - hospitalisation
    n_hosp_info, 
    n_hosp_salmonella, 
    n_hosp_other, 
    
    # 05.4 Case demographics - deaths
    n_deaths_salmonella, 
    statement_deaths_salmonella, 
    n_deaths_other, 
    statement_deaths_other
    
  ) %>% 
    
    # Convert numeric values to character:
    mutate(across(.cols = where(is.numeric), .fns = as.character)) %>% 
    
    # Transpose table:
    pivot_longer(cols = everything(), values_to = paste0("value_", suffix))

  
# Return the results table ------------------------------------------------


  return(df)

}
