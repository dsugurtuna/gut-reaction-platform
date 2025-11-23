library(tidyverse)
library(readxl)
library(lubridate)

#' Trust Data Harmonizer
#' 
#' This script standardizes disparate prescribing data formats from different NHS Trusts
#' (e.g., Leeds, Cambridge) into a Common Data Model (CDM) for the Gut Reaction Hub.
#' 
#' @param file_path Path to the raw Excel file from the Trust.
#' @param trust_id Unique identifier for the Trust (e.g., "CAMBS", "LEEDS").
#' @return A cleaned, harmonized dataframe ready for the IBD Registry.

process_trust_prescribing <- function(file_path, trust_id) {
  
  message(paste("Starting ingestion for Trust:", trust_id, "File:", file_path))
  
  # 1. Load raw data (handling the messy Excel formats typical of NHS exports)
  tryCatch({
    raw_data <- read_excel(file_path)
  }, error = function(e) {
    stop(paste("Failed to read file:", file_path, "\nError:", e$message))
  })
  
  # 2. Standardize Columns (Schema Mapping)
  # We map local column names to our internal CDM standard
  clean_data <- raw_data %>%
    rename_with(~ tolower(gsub(" ", "_", .x))) %>%
    mutate(
      trust_id = trust_id,
      
      # Drug Name Normalization (Mapping brand names to generics)
      drug_name_std = case_when(
        str_detect(drug, regex("inflix", ignore_case = TRUE)) ~ "Infliximab",
        str_detect(drug, regex("adali", ignore_case = TRUE)) ~ "Adalimumab",
        str_detect(drug, regex("vedo", ignore_case = TRUE)) ~ "Vedolizumab",
        str_detect(drug, regex("uste", ignore_case = TRUE)) ~ "Ustekinumab",
        TRUE ~ "Other"
      ),
      
      # Robust Date Parsing
      # Handling the variety of date formats (DD/MM/YYYY, YYYY-MM-DD, etc.)
      start_date = parse_date_time(rx_date, orders = c("dmy", "ymd", "mdy", "Ymd HMS")),
      
      # Data Quality Flags
      is_biologic = drug_name_std != "Other"
    ) %>%
    # Filter out invalid records or non-target drugs
    filter(!is.na(start_date)) %>%
    filter(is_biologic == TRUE) %>%
    select(trust_id, patient_id, drug_name_std, start_date, dose, frequency)
  
  message(paste("Ingestion complete. Processed", nrow(clean_data), "records."))
  return(clean_data)
}

# --- Execution Example (Commented out for library usage) ---
# cam_data <- process_trust_prescribing("inputs/CAMBS/2021-06-30_IBD_Medications.xlsx", "CAMBS")
# lth_data <- process_trust_prescribing("inputs/LEEDS/LTH21049_Prescribing.xlsx", "LEEDS")
# combined_cohort <- bind_rows(cam_data, lth_data)
# write_csv(combined_cohort, "outputs/harmonized_prescribing_cohort.csv")
