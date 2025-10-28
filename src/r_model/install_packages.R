# install_packages.R — install and load only what your model needs
options(
  repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"),
  Ncpus = parallel::detectCores()
)

needed <- c(
  "tidyverse",   # readr, dplyr, ggplot2, etc.
  "tidymodels"   # recipes, parsnip, workflows, yardstick, etc.
)

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

invisible(lapply(needed, install_if_missing))
cat("[PKG] Installed & loaded:", paste(needed, collapse = ", "), "\n")
