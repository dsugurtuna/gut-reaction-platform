library(plumber)
source("linkage_manager.R")

#* @apiTitle Genomic Bridge Service
#* @apiDescription Manages the secure linkage between Clinical TRE and Genomic HPC.

#* Health Check
#* @get /health
function() {
  list(status = "online")
}

#* Check Linkage Status (mock: always reports a link)
#* @get /status/<patient_id>
function(patient_id) {
  # Mock: does not look anything up.
  list(
    mocked = TRUE,
    patient_id = patient_id,
    has_linkage = TRUE,
    sanger_id = paste0("SANGER_", patient_id)
  )
}

#* Execute Cohort Linkage
#* @post /link-cohort
#* @param cohort_file Path to the clinical cohort definition
function(cohort_file) {
  
  tryCatch({
    # Call the core logic
    linked_data <- link_clinical_to_genomic(
      cohort_file, 
      "/data/secure/mpi_bridge.csv", 
      "/hpc/manifests/genomic_inventory.csv"
    )
    
    return(list(
      status = "success",
      linked_count = nrow(linked_data),
      export_path = "/data/exports/linked_cohort_latest.csv"
    ))
    
  }, error = function(e) {
    list(status = "error", message = e$message)
  })
}

# The container starts the API with:
#   Rscript -e "plumber::pr_run(plumber::pr('start_linkage_service.R'), host = '0.0.0.0', port = 8000)"
