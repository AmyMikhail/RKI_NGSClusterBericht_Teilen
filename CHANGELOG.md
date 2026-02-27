Changelog
================
Amy Mikhail
27 February 2026

<!-- Changelog.md is generated from Changelog.Rmd. Please edit that file -->

### Background:

This change log is a summary of historical issues and how they were
solved. It was compiled initially to serve as a record of changes for
audit purposes, but also serves as a learning resource. Only substantive
changes are recorded here, and they are ordered by date (most recent
first).

### Issue 24: 2023-11-18 Minor edits to tables and figures

**Problem statement:**

The following minor issues to be addressed:

1.  The label of the age boxplot and the sex pie chart says: “Abb. : (A)
    Boxplot des Alters, geschichtet nach Geschlecht; (B) Kuchendiagramm
    der Geschlechterverteilung” . Since we do not stratify by sex
    anymore it should instead say “Abb. : (A) Boxplot des Alters; (B)
    Kuchendiagramm der Geschlechterverteilung”
2.  In the table “Krankenhausaufenthalte und Todesfälle” the last column
    is labelled “Fälle insgesamt 1”, however I think it should rather
    say “n (%) 1”, since there is no total in this column.
3.  In the Shiny app that allows selection of parameters to knit with,
    the options in the dropdown menu for the last parameter (what to
    stratify the epicurve with) are not visible (dialogue box is not big
    enough)
4.  The ordering of the cause of death is different between this table
    and the one before called “Krankenhausaufenthalte und Todesfälle”.
    If not too much work, it would be great to have this consistent:
    either first the death due to salmonellosis and then due to other
    causes or the inverse.

**Proposed solutions:**

Fix minor errors in labels, titles and tables as described above.

For the knit with parameters dialogue box: change to radio buttons
instead as there are only two options

------------------------------------------------------------------------

### Issue 23: 2023-10-09 Double-counting of hospitalised patients who died

**Problem statement:**

The severity by age group table (Hospitalisierungsstatus und Todesfälle
nach Altersgruppe) should summarise hospitalisations and deaths
separately (so a hospitalised case that also died will be counted in two
places) rather than the current behaviour, which assigns each case only
one outcome (the most severe one) meaning that a hospitalised case who
died is only appearing in the death statistics but not hospitalisation
statistics.

*Current behaviour:*

Severity is currently assigned as follows:

1.  Not hospitalised and not dead: the least severe outcome of interest
2.  Hospitalised and not dead, but hospitalisation was due to a cause
    other than Salmonella: next least severe outcome of interest
3.  Hospitalised and not dead, where hospitalisation was due to
    Salmonellosis: next most severe outcome of interest
4.  Dead (irrespective of prior hospitalisation) but not due to
    Salmonella: next most severe outcome of interest
5.  Dead (irrespective of prior hospitalisation) due to Salmonellosis:
    most severe outcome of interest

Note that hospitalisation and death statistics are calculated separately
in all other figures, graphs and tables in the document.

**Proposed solution:**

Instead of using severity, create two separate tables with
janitor::tabyl() for hosp_final by age group and death_final by age
group, then merge them before formatting as a heatmap table.

------------------------------------------------------------------------

### Issue 21: 2023-09-30 Cluster name not found unless outbreak is declared

**Problem statement:**

The following error occurs if `params$outbreak_declared = FALSE`:

``` r

Quitting from lines 756-947 [get_outbreak_details] (ClusterBericht.Rmd)
Error in `paste0()`:
! Objekt 'clustername' nicht gefunden
Backtrace:
 1. base::ifelse(...)
 2. base::paste0(...)
Ausführung angehalten
```

**Further details:**

Clustername is being extracted from the line list after the title of the
report is conditionally updated with clustername, causing this error.

**Proposed solution:**

Move `report_title <- ...` to the end of the chunk after clustername is
defined.

------------------------------------------------------------------------

### Isue 20: 2023-09-30 Case count for first Bundesland in summary looks wrong

**Problem statement:**

The number of cases for the first Bundesland listed in the executive
summary text is incorrect.

**Further details:**

When `params$previous_report = FALSE` or if there are no changes in the
number of cases per Bundesland since the last report, the total number
of Bundesland with no cases and no change is printed directly before the
number of cases in the first listed Bundesland, making it look like a
much larger number than it should be.

**Proposed solution:**

Make the printing of `bundesland_nochange_n` conditional on
`params$previous_report = TRUE`:

``` r

if(showbundsame & params$previous_report){colourtext('bundesland_nochange_n')}
```

------------------------------------------------------------------------

### Issue 19: 2023-09-25 Snaglist edits

**Notes on edits:**

1.  The code to conditionally show the number of cases by each case
    definition was quite heavy, so it has been supressed but not deleted
    in the r markdown in case you want this again. Press
    `Ctr + shift + c` on the supressed paragraph to unsuppress.
2.  The Bundesland map now has the colour scheme of the second map
    (easier to distinguish between colours) and the incidence ranges are
    added to the legend dynamically. I have removed the quartile text
    labels however, as for smaller numbers of values, not all of the
    quartiles will be used so it makes more sense this way.
3.  Case numbers were added to the top 5 Kreise table - however please
    note it is showing top 5 by incidence rather than case numbers, as
    it is meant to provide some annotation to the map, since aligning
    the labels outside the map was not possible.
4.  The median point and label are removed from the age boxplot as it
    was not possible to show them when there is no x axis (categorical)
    variable. However the footnote still shows the median age.
5.  I removed the incorrect `N = 21` at the top of the hospitalisation
    and deaths table all together, as the correct number would be a
    repetition of total with hospital info, which is displayed below in
    any case so it is not needed twice.

------------------------------------------------------------------------

### Issue 18: 2023-09-22 Incorrect number of cases per federal state

**Problem statement:**

The number of cases per federal state (bundesland) has been calculated
incorrectly in one report.

**Troubleshooting details:**

The report has classified as unknown three cases that have a value for
bundesland_final in the linelist. This was due to the following reasons:

1.  `clean_data()` currently gets bundesland lettercode from
    `pop_berlin` by joining on `kreise_final` column in the linelist,
    and not all cases with a value for bundesland_final also have a
    value for kreise_final. In two of the three cases there was a value
    for Bundesland but not Kreise.
2.  There is no population for the Kreise LK Osterode am Harz and this
    Kreise is missing alltogether from the pop_berlin data, therefore
    there was no corresponding kreise_final value to join the bundesland
    lettercode on.

**Proposed solution:**

Get the bundesland_lettercode column from `pop_bundesland` instead of
`pop_kreise`. This will ensure that when there is a value for Bundesland
but not Kreise, that the affected case(s) will be included in the
summary counts and tables by bundesland_lettercode.

Also use `coalesce()` for consolidated columns where possible instead of
`ifelse()` and / or `case_when()` as the code is simpler.

**Other issues with epicurve:**

Also note that x axis labels (dates by month with three-letter name) for
multi-year epicurve are overlapping and cramped. Add a third option to
display by quarter for multi-year epicurves.

Set `epicurve_interval = "3 months"` and use format `"%m"` as there is
no year quarter option in strptime().

Small numbers on y axis of epicurve not showing as whole integers -
corrected with this solution:

``` r

# Add to ggplot:
scale_y_continuous(breaks = ~round(unique(pretty(.))))
```

------------------------------------------------------------------------

### Issue 17: 2023-09-10 Age severity table missing

**Problem statement:**

The following error is occuring when running the report on the latest
line list:

``` r

Quitting from lines 2703-2753 [severity_heatmap] (ClusterBericht.Rmd)
Error in `add_header_row()`:
! sum of colwidths elements must be equal to the number of col_keys: 16.
Backtrace:
  1. ... %>% set_table_properties(layout = "autofit")
 11. flextable::add_header_row(...)
```

**Proposed solutions:**

The table is a cross-tabulation of severity and age categories, both of
which are factors. When adding the merged upper header to the table, the
number of columns specified for each header to span must match the
number of columns that actually exist in the table. It is possible that
if there is a missing value in age categories, this is adding an extra
column to the table so that the total number of columns to span doesn’t
match (number of columns to span is determined by
`nlevels(linelist$age_cat)`).

The solution would be: `drop_na(age_cat)` before piping the data into
the table.

------------------------------------------------------------------------

### Issue 16: 2023-09-10 Age sex boxplot not generated if sex is missing

**Problem statement:**

The following error occurs when running the report on a line list where
one case is missing a value for sex:

``` r


Quitting from lines 2230-2367 [agesex_piebox] (ClusterBericht.Rmd)

Error in `geom_boxplot()`:
! Problem while setting up geom aesthetics.
ℹ Error occurred in the 1st layer.

Caused by error in `check_aesthetics()`:
! Aesthetics must be either length 1 or the same as the data (3)
✖ Fix the following mappings: `fill`

Backtrace:
  1. gridExtra::grid.arrange(age_boxplot, sex_piechart, ncol = 2)
  2. gridExtra::arrangeGrob(...)
  3. base::lapply(grobs[toconv], ggplot2::ggplotGrob)
  4. ggplot2 (local) FUN(X[[i]], ...)
  9. ggplot2:::ggplot_build.ggplot(x)
     ...
 18. l$compute_geom_2(d)
 19. ggplot2 (local) compute_geom_2(..., self = self)
 20. self$geom$use_defaults(data, self$aes_params, modifiers)
 21. ggplot2 (local) use_defaults(..., self = self)
 22. ggplot2:::check_aesthetics(params[aes_params], nrow(data))
```

**Possible solution:**

This may be due to `sexcolours` not having the right number of colours
for the boxplot if one sex is missing. This could be solved as follows:

``` r

# Create named list for the colour palate:
sexcolours <- setNames(object = c("#B9CDE5",
                                  "#E6B9B8"), 
                        nm = c('männlich',
                               'weiblich'))

# Define what values of sex exist in the data:
sexindata <- linelist %>% 
  select(sex_final) %>% 
  pull() %>% 
  unique()

# Restrict sexcolours to what actually exists in the data:
sexcolours <- subset(sexcolours, names(sexcolours) %in% sexindata)
```

Also, I have more explicitly handled missing values by ensuring that
`drop_na()` is applied to the relevant columns before piping into graphs
or tables.

------------------------------------------------------------------------

### Issue 15: 2023-09-06 R markdown knit fails at age sex graphs

**Problem statement:**

The following error occurs when knitting the report with a new data set:

``` r

|....................................       |  83% [agesex_piebox]           
Quitting from lines 2229-2366 [agesex_piebox] (ClusterBericht.Rmd)
Error in `geom_boxplot()`:
! Problem while setting up geom aesthetics.
? Error occurred in the 1st layer.
Caused by error in `check_aesthetics()`:
! Aesthetics must be either length 1 or the same as the data (3)
? Fix the following mappings: `fill`
Backtrace:
  1. gridExtra::grid.arrange(age_boxplot, sex_piechart, ncol = 2)
  2. gridExtra::arrangeGrob(...)
  3. base::lapply(grobs[toconv], ggplot2::ggplotGrob)
  4. ggplot2 (local) FUN(X[[i]], ...)
  9. ggplot2:::ggplot_build.ggplot(x)
     ...
 18. l$compute_geom_2(d)
 19. ggplot2 (local) compute_geom_2(..., self = self)
 20. self$geom$use_defaults(data, self$aes_params, modifiers)
 21. ggplot2 (local) use_defaults(..., self = self)
 22. ggplot2:::check_aesthetics(params[aes_params], nrow(data))
```

**Proposed solution:**

On further investigation, it seems that the problem is with the
generation of `isolate_birthage` because this column requires
subtracting `isolate_birthdate` from `isolate_submitdate`. There are no
values for `isolate_submitdate` in the tested linelist.

To resolve this, if `isolate_submitdate` is missing, the code will use
`isolate_receiptdate` instead. Code in the `clean_data()` function has
been updated to incorporate this as below:

``` r

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
    mutate(age_final = ifelse(test = is.na(case_calculatedage), 
                              yes = isolate_birthage, 
                              no = case_calculatedage))
```

It is interesting that the error didn’t occur until the graphs, as when
the R markdown is run chunk by chunk, it stops when the `clean_data()`
function is applied to the imported linelist (which is what I would have
expected, given that is where the issue was).

------------------------------------------------------------------------

### Issue 14: 2023-09-06 Kreise map error with geom() and jenks

**Problem statement:**

The following error occurs for the Kreise map:

``` r

quitting from lines 1446-1640 [kreise_map] (ClusterBericht.Rmd)

Error in `stopifnot()`:
ℹ In argument: `incidence_breaks = cut(...)`.
Caused by error in `cut.default()`:
! 'breaks' sind nicht eindeutig
Backtrace:
  1. ... %>% arrange(desc(incidence))
 17. base::cut.default(...)
 18. base::stop("'breaks' are not unique")
Ausführung angehalten
```

It seems that when a high proportion of the polygons have an incidence
of 0 cases per 100,000 population, the geom method interprets them as
taking up a larger part of the spread of the data, therefore calculates
fewer interval categories. The jenks method seems to be more robust in
this scenario, as it just ignores the 0s.

It may however be necessary to force use of pretty breaks with automated
labelling if the number of categories is less than four.

While the jenks method improves the distribution of interval categories,
it seems that when kreise with 0 cases are included, jenks method
created breaks that contained duplicate values (two zeros). One set of
0s were integers and the other set had decimal places in the incidence
column. It is not clear why this happened and they are both classified
as numeric.

**Proposed solutions:**

Checking through the other methods, fisher seems to be more robust (does
not create duplicate break values in this example) and is actually based
on the same principles as jenks but an improved version. I have now made
this the default method and increased the number of classes to 5 (as the
first one is not really a quartile, just 0). I think this should correct
the labelling problem, but the manual labels will still be incorrect if
there are fewer than five break points (including 0).

An alternative option that I have included in this commit is the same
map, but produced using the `{mapsf}` package. The code is more compact
although some of the default parameters are more difficult to change
than with ggplot. It has the following two differences, which may make
it more robust across different data sets:

1.  I left kreise that had not reported any cases as NA in the data set
    rather than recoding them to 0 (they are still white);
2.  The legend labels are automatically generated as just values (no
    manual text), so if there are fewer than 5 break points, it should
    still print a sensible legend.

The only down side to the mapsf map is that it is a little smaller
\[Note: mapsf map removed in later versions as the decision was made to
stick with ggplot and `geom_sf()` for consistency\].

------------------------------------------------------------------------

### Issue 08: 2023-08-22 Kriese map labelling issues

**Problem statement:**

1.  The top 5 incidence labels are currently layered ontop of and
    therefore obscuring some districts on the map.
2.  The first colour in the palatte is difficult to distinguish from
    white (white is used for districts with no cases).

**Proposed solution:**

For map labels:

- Try modifying the solution in this [StackOverflow
  post](https://stackoverflow.com/questions/71686257/how-do-i-make-ggrepel-move-some-labels-outside-us-map-boundaries)
  (see second solution) to put the labels outside the map area and align
  them.
- If that doesn’t work, remove the labels alltogether (could optionally
  put the top 5 or 10 in a table below the map).

For colour palatte:

- Manually define and use easier to distinguish colours that start with
  a darker blue.

------------------------------------------------------------------------

### Issue 07: 2023-08-22 Epicurve overcrowded

**Problem statement:**

Currently there is not enough space on a \[portrait orientation\] page
to show an epicurve by weeks for an outbreak spanning longer than 20
weeks. Changing the section to landsacpe orientation causes other
difficulties with the headers and footers (see issue \#6 ).

**Proposed solution:**

If outbreak is longer than 20 weeks, in addition to defaulting to an
epicurve by months, add another epicurve by weeks showing only the most
recent 20 weeks.

------------------------------------------------------------------------

### Issue 06: 2023-08-22 Make more space for wide figures and tables

**Problem statement:**

Epicurves with long time frames and the Bundesland table are too wide
for the page in the output document with current settings.

**Proposed solutions:**

It is possible to make a page landscape in an R markdown report by
putting the following HTML tags before and after the relevant sections
instead of page breaks:

``` r

<!---BLOCK_LANDSCAPE_START--->

Contents to appear in landscape orientation here...

<!---BLOCK_LANDSCAPE_STOP--->
```

I tried this, but unfortunately it makes all the headers and footers
from the reference_docx dissappear (I suspect because they are no longer
in the right place for a landscape page).

For this reason I will still be adding an extra epicurve by week for the
most recent 20 weeks after the epicurve by months, rather than
displaying the whole outbreak epicurve in weeks if it lasted for longer
than 20 weeks.

The wide Bundesland table has been made a bit narrower by orienting some
of the column titles to 90 degrees.

------------------------------------------------------------------------

### Issue 05: 2023-08-12 R markdown failing to knit

Problem statement:

Until now, the report has only been tested on one example data set. When
it was tested on a new data set, it failed to knit with the following
error:

``` r

Quitting from lines 701-727 (ClusterBericht.Rmd)
Error in `mutate()`:
? In argument: `epicurve_dates = case_when(...)`.
Caused by error in `case_when()`:
! Failed to evaluate the left-hand side of formula 2.
Caused by error:
! Objekt 'case_reportdate' nicht gefunden
Backtrace:
  1. ... %>% clean_data()
 22. dplyr::case_when(...)
 23. dplyr:::case_formula_evaluate(...)
 25. rlang::eval_tidy(pair$lhs, env = default_env)

Warnmeldung:
In do_once((if (is_R_CMD_check()) stop else warning)("The function xfun::isFALSE() will be deprecated in the future. Please ",  :
  The function xfun::isFALSE() will be deprecated in the future. Please consider using base::isFALSE(x) or identical(x, FALSE) instead.
Ausführung angehalten
```

**Possible causes:**

The report is not able to locate the case_reportdate column. This is due
to the original name of this column being `Meldedatum` which is
duplicated in one of the hidden columns. On importing the data, the
{rio} package tries to clean up the column names and assigns any
duplicates a suffix with the column number. The column number is not
matching what is in the data dictionary in this case, because the new
data set has two extra columns.

**Proposed solutions:**

1.  When importing the linelist, set the `rio::import()` argument
    `.name_repair = "minimal"`. This will prevent it from assigning a
    suffix to duplicate column names. In the `clean_data()` function,
    `janitor::clean_names()` will assign a suffix (serial number) to the
    second and subsequent duplicate column names, but not the first one.
    The data dictionary (datenlexikon) has been updated to reflect this
    more stable handling of duplicate column names.
2.  Note that the case definition column (which is under the manual text
    section in yellow in the line list) does not always have the same
    capitalisation. In the example data set, data in this column was
    capitalised. In the new data set, the data is lower case, which
    prevented it from being converted to a factor and matched to the
    appropriate (ordered) levels. This has been solved by applying
    `stringr::str_to_sentence()` to the column. Note it is not possible
    to apply this function to all the character columns in the linelist,
    because the geography columns have very specific patterns of
    capitalisation which need to match that in the population data so
    that they can be merged together. If possible that capitalisation
    could vary in other columns, a broader solution will have to be
    applied.
3.  The hospital boxplot applies a colour scheme with three levels
    outside the `aes()`. This needs to be trimmed when there are less
    than three levels, otherwise the boxplot will fail to render as the
    number of colours provided is greater than the number of factor
    levels to present. The code has been updated to trim the colour
    scheme dynamically according to the number of levels present in
    `hosp_final`.
4.  The new data set does not have any serovar information from the lab.
    This results in a blank space in the relevant sentence in the
    summary text, as well as a blank space in the summary information
    table on the first page. To check whether the serovar sentence
    should be made to appear conditionally.

*Note:* Not all users get the warning about function deprecation after
the error - the reason for this is detailed
[here](https://yihui.org/en/2023/02/xfun-isfalse/). I need to check if
one of the dependent packages is using the function that is about to be
deprecated, although in theory none are.

------------------------------------------------------------------------

### Issue 04: 2023-08-10 Previous and current line list required for knit

**Problem statement:**

If `params$previous_report == FALSE` the report fails to knit with the
following error:

``` r

Quitting from lines 750-906 (ClusterBericht.Rmd)
Fehler in janitor::tabyl(., bundesland_lettercode, show_na = FALSE) :
  Objekt 'linelist_old' nicht gefunden
Ruft auf: <Anonymous> ... compare_bundesland -> %>% -> rename -> select -> arrange -> <Anonymous>
Zusätzlich: Warnmeldung:
In do_once((if (is_R_CMD_check()) stop else warning)("The function xfun::isFALSE() will be deprecated in the future. Please ",  :
  The function xfun::isFALSE() will be deprecated in the future. Please consider using base::isFALSE(x) or identical(x, FALSE) instead.
Ausführung angehalten
```

**Further details:**

The import of a previous line list (chunk starting line 730) is
conditional on the previous_report parameter (checkbox) being ticked.
The summary values `previousvals` are also conditional on this
parameter. However the conditional statement was forgotten for the
Bundesland comparison (starting line 808) - this does refer to
linelist_old and is probably why the report is failing to knit. In
addition, if you tick the checkbox but don’t upload a previous linelist,
the `linelist_previous.xlsx` from the data folder is automatically
uploaded as this was added as the default.

**Proposed solution:**

1.  In the first instance, check that the unticked checkbox does result
    in `params$previous_report == FALSE`.
2.  Then, make the bundesland comparison table use the old linelist
    conditionally, as the other summary values already do.
3.  Also remove the old linelist default from the relevant file upload
    parameter in the YAML header of the R markdown script.

I changed the code to use only whether or not `params$previous_report`
is ticked or not instead of checking to see if linelist_old exists. This
means the example line lists (current and previous) can still be kept as
defaults for testing, but the old linelist will not be used if this
parameter is `FALSE`.

------------------------------------------------------------------------

### Issue 01: 2023-06-27 Handling 0 deaths in summary text

**Problem statement:**

The last two sentences in the summary text may not make sense if there
are 0 deaths.

**Proposed solution:**

Artificially remove the deaths and see what happens. Adjust how the text
displays accordingly. The statements with number of deaths can be left
in (it will just say 0) but the demographic statements in parentheses
need to be conditionally filtered out if there are no deaths at all.

------------------------------------------------------------------------
