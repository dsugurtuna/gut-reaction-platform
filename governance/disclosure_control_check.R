library(tidyverse)

#' Statistical Disclosure Control (SDC) Validator
#' 
#' Automated governance script to enforce "Safe Outputs" under the ONS Five Safes framework.
#' Scans potential export files for "small number" disclosure risks before they can
#' be moved to the Airlock.
#' 
#' @param output_dataframe The data intended for release.
#' @param threshold The minimum count required for k-anonymity (default: 5).
#' @return Boolean (TRUE if safe, FALSE if risk detected).

check_for_disclosure_risk <- function(output_dataframe, threshold = 5) {
  
  message(paste("Running SDC Governance Check. Threshold: <", threshold))
  
  # 1. Identify categorical columns (High risk of small cells)
  categorical_cols <- output_dataframe %>% 
    select(where(is.character) | where(is.factor)) %>% 
    names()
  
  risk_flags <- list()
  
  # 2. Check low counts in cross-tabulations
  # We iterate through every categorical variable to ensure no category has < 5 observations.
  for (col in categorical_cols) {
    low_counts <- output_dataframe %>%
      count(.data[[col]]) %>%
      filter(n < threshold)
    
    if (nrow(low_counts) > 0) {
      risk_msg <- paste("ALERT: Found", nrow(low_counts), "categories in column '", col, "' with n <", threshold)
      risk_flags[[col]] <- risk_msg
      warning(risk_msg)
    }
  }
  
  # 3. Final Verdict
  if (length(risk_flags) > 0) {
    message("\n[FAILED] Disclosure Risk Detected. Do not release this file.")
    print(risk_flags)
    return(FALSE)
  } else {
    message("\n[PASSED] No small cell counts detected. File is safe for Airlock transfer.")
    return(TRUE)
  }
}

# --- Mock Usage ---
# df <- read_csv("outputs/commercial_release_v1.csv")
# is_safe <- check_for_disclosure_risk(df)
# if(is_safe) { file.copy("outputs/commercial_release_v1.csv", "airlock/") }
