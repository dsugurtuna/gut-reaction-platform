library(plumber)
source("linkage_manager.R")

#* @apiTitle Genomic Bridge Service
#* @apiDescription Manages the secure linkage between Clinical TRE and Genomic HPC.

#* Check Linkage Status
#* @get /status/<patient_id>
function(patient_id) {
  # Mock check against a database or file
  list(
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
