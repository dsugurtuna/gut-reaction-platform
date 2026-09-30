library(plumber)
library(checkmate)
source("trust_data_harmonizer.R")

#* @apiTitle Clinical Ingestion Service
#* @apiDescription Standardises drug names and dates in hospital prescribing extracts.

#* Health Check
#* @get /health
function() {
  list(status = "online", backend = "R 4.2.0")
}

#* Harmonise one prescribing extract
#* @post /harmonize
#* @param input_file Path, on the server, to the raw Excel (.xlsx) extract
#* @param trust_id Site code accepted by process_trust_prescribing()
function(input_file, trust_id) {
  
  # Validate input
  if (!file.exists(input_file)) {
    return(list(status = "error", message = "File not found"))
  }
  
  tryCatch({
    message(sprintf("Starting harmonisation for %s", input_file))
    
    result <- process_trust_prescribing(input_file, trust_id)
    
    return(list(
      status = "success",
      rows_processed = nrow(result),
      message = "Drug names standardised and rows passing QC kept (flat table, not OMOP CDM)"
    ))
    
  }, error = function(e) {
    return(list(status = "error", message = conditionMessage(e)))
  })
}

# The container starts the API with:
#   Rscript -e "plumber::pr_run(plumber::pr('start_api.R'), host = '0.0.0.0', port = 8000)"
