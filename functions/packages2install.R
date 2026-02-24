###############################################################
# INSTALL PACKAGES
###############################################################

# 1. Remotes:
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")

# 2. Pacman:
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")

# 3. Install all required CRAN packages:
pacman::p_load(
  rmarkdown,
  knitr,
  shiny,
  bookdown,
  officedown,
  officer,
  here, 
  rio, 
  safer,
  janitor,
  flextable,
  ftExtra,
  ztable,
  gtsummary, 
  gridExtra,
  ggrepel,
  ggtext,
  scales,
  sf, 
  mapsf,
  ggmap,
  epikit, 
  apyramid, 
  tidyverse
)

# 4. All required GitHub packages:
pacman::p_load_gh(
  
  "yutannihilation/ggsflabel"
  
)


# 5. Install latex (tinytex):
tinytex::install_tinytex()
