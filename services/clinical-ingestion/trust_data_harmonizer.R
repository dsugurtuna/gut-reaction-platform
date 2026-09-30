library(tidyverse)
library(readxl)
library(lubridate)
library(checkmate) # For robust assertions
source("harmonizer_rules.R")

#' Trust Data Harmonizer
#' 
#' Reads one hospital prescribing extract (Excel), standardises column names,
#' drug names and dates, and keeps rows that pass two data-quality checks.
#' The output is a flat table, not an OMOP CDM table.
#' 
#' @param file_path Path to the raw Excel file.
#' @param trust_id Unique identifier for the Trust.
#' @return A cleaned, harmonized dataframe.

process_trust_prescribing <- function(file_path, trust_id) {
  
  # --- 1. Input Validation ---
  assert_file_exists(file_path)
  assert_choice(trust_id, VALID_TRUST_IDS)
  
  message(sprintf("[%s] Starting ingestion for Trust: %s", Sys.time(), trust_id))
  
  # --- 2. Robust Ingestion ---
  raw_data <- tryCatch({
    read_excel(file_path)
  }, error = function(e) {
    stop(sprintf("CRITICAL: Failed to read file %s. Error: %s", file_path, e$message))
  })
  
  # --- 3. Schema Normalization ---
  # Map local column names to CDM standard
  clean_data <- raw_data %>%
    rename_with(normalise_column_names)
    
  # --- 4. Business Logic Transformation ---
  clean_data <- clean_data %>%
    mutate(
      trust_id = trust_id,
      
      # Drug name standardisation (regex -> standard name), see harmonizer_rules.R
      drug_name_std = standardise_drug(drug),
      
      # Date Parsing with Fallback
      start_date = parse_date_time(rx_date, orders = c("dmy", "ymd", "mdy", "Ymd HMS")),
      
      # Data Quality Flags
      dq_valid_date = !is.na(start_date),
      dq_target_drug = drug_name_std != "Other"
    )
  
  # --- 5. Quality Control Filter ---
  final_cohort <- clean_data %>%
    filter(dq_valid_date & dq_target_drug) %>%
    select(trust_id, patient_id, drug_name_std, start_date, dose, frequency)
  
  # --- 6. Audit Logging ---
  dropped_count <- nrow(clean_data) - nrow(final_cohort)
  if (dropped_count > 0) {
    warning(sprintf("QC Alert: Dropped %d records due to invalid dates or non-target drugs.", dropped_count))
  }
  
  message(sprintf("[%s] Ingestion complete. Valid records: %d", Sys.time(), nrow(final_cohort)))
  return(final_cohort)
}

# --- Execution Example (Commented out for library usage) ---
# site_a <- process_trust_prescribing("inputs/site_a/prescribing_extract.xlsx", "CAMBS")
# site_b <- process_trust_prescribing("inputs/site_b/prescribing_extract.xlsx", "LEEDS")
# combined_cohort <- bind_rows(site_a, site_b)
# write_csv(combined_cohort, "outputs/harmonized_prescribing_cohort.csv")
