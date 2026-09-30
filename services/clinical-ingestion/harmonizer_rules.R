# Pure harmonisation rules, kept apart from file I/O so the unit tests can
# exercise the same code the service runs. Needs only dplyr and stringr.
library(dplyr)
library(stringr)

# Site codes accepted by process_trust_prescribing().
VALID_TRUST_IDS <- c("CAMBS", "LEEDS", "MANCH", "LPOOL")

#' Map free-text drug names to a standard name.
#'
#' Case-insensitive regex match on generic and brand names for four biologics
#' used in inflammatory bowel disease. Anything else becomes "Other".
#'
#' @param drug Character vector of drug names as written in the source extract.
#' @return Character vector of the same length.
standardise_drug <- function(drug) {
  dplyr::case_when(
    stringr::str_detect(drug, stringr::regex("inflix|remicade", ignore_case = TRUE)) ~ "Infliximab",
    stringr::str_detect(drug, stringr::regex("adali|humira", ignore_case = TRUE)) ~ "Adalimumab",
    stringr::str_detect(drug, stringr::regex("vedo|entyvio", ignore_case = TRUE)) ~ "Vedolizumab",
    stringr::str_detect(drug, stringr::regex("uste|stelara", ignore_case = TRUE)) ~ "Ustekinumab",
    TRUE ~ "Other"
  )
}

#' Lower-case column names and replace spaces with underscores.
normalise_column_names <- function(names) {
  tolower(gsub(" ", "_", names))
}
