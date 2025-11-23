library(plumber)
library(checkmate)
source("trust_data_harmonizer.R")

#* @apiTitle Clinical Ingestion Service
#* @apiDescription Standardizes NHS Trust data into the OMOP Common Data Model.

#* Health Check
#* @get /health
function() {
  list(status = "online", backend = "R 4.2.0")
}

#* Trigger Data Harmonization Batch
#* @post /harmonize
#* @param input_file The path to the raw CSV file
function(input_file) {
  
  # Validate input
  if (!file.exists(input_file)) {
    return(list(error = "File not found"))
  }
  
  tryCatch({
    message(sprintf("Starting harmonization for %s", input_file))
    
    # Call the core logic from the sourced script
    # (Assuming harmonize_trust_data is the main function)
    result <- harmonize_trust_data(input_file, "mappings/omop_map.csv")
    
    return(list(
      status = "success",
      rows_processed = nrow(result),
      message = "Data successfully mapped to OMOP CDM"
    ))
    
  }, error = function(e) {
    return(list(status = "error", message = e$message))
  })
}

# Programmatic start
# pr <- plumber::plumb("start_api.R")
# pr$run(host = "0.0.0.0", port = 8000)
