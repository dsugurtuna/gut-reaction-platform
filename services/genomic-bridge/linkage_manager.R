library(tidyverse)
library(data.table)
library(checkmate)

#' Genomic Linkage Manager
#' 
#' Bridges the "Air Gap" between the Clinical Trusted Research Environment (TRE)
#' and the High Performance Computing (HPC) cluster.
#' 
#' This script manages the Master Patient Index (MPI) to link clinical phenotypes
#' with genomic assets (WES, SNP Arrays) without exposing patient identities.

link_clinical_to_genomic <- function(clinical_cohort_file, linkage_key_file, genomic_manifest_file) {
  
  message(sprintf("[%s] Initiating Secure Linkage Protocol...", Sys.time()))
  
  # --- 1. Input Validation ---
  assert_file_exists(c(clinical_cohort_file, linkage_key_file, genomic_manifest_file))
  
  # --- 2. Load Clinical Cohort (TRE) ---
  clinical_data <- fread(clinical_cohort_file)
  assert_subset(c("patient_id", "recruitment_site"), names(clinical_data))
  
  message(sprintf("Clinical Cohort Size: %d patients", nrow(clinical_data)))
  
  # --- 3. Load Bridge File (MPI) ---
  # STRICT ACCESS CONTROL: This file maps internal IDs to Sanger IDs
  bridge <- fread(linkage_key_file)
  assert_subset(c("patient_id", "sanger_sample_id"), names(bridge))
  
  # --- 4. Perform Linkage ---
  linked_cohort <- clinical_data %>%
    inner_join(bridge, by = "patient_id") %>%
    filter(!is.na(sanger_sample_id))
  
  message(sprintf("Successfully Linked Patients: %d (Match Rate: %.1f%%)", 
                  nrow(linked_cohort), (nrow(linked_cohort)/nrow(clinical_data))*100))
  
  # --- 5. Check Genomic Availability (HPC Manifest) ---
  genomic_inventory <- fread(genomic_manifest_file)
  
  final_export_list <- linked_cohort %>%
    inner_join(genomic_inventory, by = "sanger_sample_id") %>%
    mutate(
      # Check for file existence (Mock paths for shadow repo)
      has_wes = file.exists(paste0("/mnt/hpc/data/wes/cram/", sanger_sample_id, ".cram")),
      has_snp = file.exists(paste0("/mnt/hpc/data/snp/plink/", sanger_sample_id, ".bed")),
      
      # Quality Control Check
      qc_pass = qc_status == "PASS" & contamination_rate < 0.05
    )
  
  # --- 6. Filter for Valid Export ---
  valid_export <- final_export_list %>%
    filter(qc_pass == TRUE & (has_wes | has_snp)) %>%
    select(patient_id, sanger_sample_id, phenotype_status, has_wes, has_snp)
  
  message(sprintf("Final Validated Cohort for Export: %d", nrow(valid_export)))
  
  return(valid_export)
}

# --- Usage Example ---
# target_list <- link_clinical_to_genomic(
#   "requests/DAA102/clinical_cohort.csv",
#   "secure/MPI_July2022.csv",
#   "manifests/Sanger_Manifest_v4.csv"
# )
# write_csv(target_list, "outputs/DAA102_genomic_pull_list.csv")
