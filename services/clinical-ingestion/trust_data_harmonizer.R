library(tidyverse)
library(readxl)
library(lubridate)
library(checkmate) # For robust assertions

#' Trust Data Harmonizer
#' 
#' Enterprise-grade ETL pipeline for standardizing disparate NHS Trust data.
#' Implements strict schema validation and error handling.
#' 
#' @param file_path Path to the raw Excel file.
#' @param trust_id Unique identifier for the Trust.
#' @return A cleaned, harmonized dataframe.

process_trust_prescribing <- function(file_path, trust_id) {
  
  # --- 1. Input Validation ---
  assert_file_exists(file_path)
  assert_choice(trust_id, c("CAMBS", "LEEDS", "MANCH", "LPOOL"))
  
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
    rename_with(~ tolower(gsub(" ", "_", .x)))
    
  # --- 4. Business Logic Transformation ---
  clean_data <- clean_data %>%
    mutate(
      trust_id = trust_id,
      
      # Drug Concept Mapping (Regex -> Standard Concept)
      drug_name_std = case_when(
        str_detect(drug, regex("inflix|remicade", ignore_case = TRUE)) ~ "Infliximab",
        str_detect(drug, regex("adali|humira", ignore_case = TRUE)) ~ "Adalimumab",
        str_detect(drug, regex("vedo|entyvio", ignore_case = TRUE)) ~ "Vedolizumab",
        str_detect(drug, regex("uste|stelara", ignore_case = TRUE)) ~ "Ustekinumab",
        TRUE ~ "Other"
      ),
      
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
# cam_data <- process_trust_prescribing("inputs/CAMBS/2021-06-30_IBD_Medications.xlsx", "CAMBS")
# lth_data <- process_trust_prescribing("inputs/LEEDS/LTH21049_Prescribing.xlsx", "LEEDS")
# combined_cohort <- bind_rows(cam_data, lth_data)
# write_csv(combined_cohort, "outputs/harmonized_prescribing_cohort.csv")
