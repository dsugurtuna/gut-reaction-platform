# Pure linkage rules, kept apart from file I/O so the unit tests can exercise
# the same code the service runs. Needs only dplyr.
library(dplyr)

# Maximum contamination rate for a sample to count as usable.
MAX_CONTAMINATION_RATE <- 0.05

#' Join a clinical cohort to the pseudonymised bridge table.
#'
#' Keeps only patients that have a genomic sample ID in the bridge.
link_cohort <- function(clinical_data, bridge) {
  clinical_data %>%
    dplyr::inner_join(bridge, by = "patient_id") %>%
    dplyr::filter(!is.na(sanger_sample_id))
}

#' Keep samples that pass QC and have at least one data file.
#'
#' Expects qc_status, contamination_rate, has_wes and has_snp columns.
select_exportable <- function(samples, max_contamination = MAX_CONTAMINATION_RATE) {
  samples %>%
    dplyr::filter(qc_status == "PASS" & contamination_rate < max_contamination & (has_wes | has_snp))
}
