library(tidyverse)
library(data.table)

#' Genomic Linkage Manager
#' 
#' Bridges the "Air Gap" between the Clinical Trusted Research Environment (TRE)
#' and the High Performance Computing (HPC) cluster.
#' 
#' This script manages the Master Patient Index (MPI) to link clinical phenotypes
#' with genomic assets (WES, SNP Arrays) without exposing patient identities.

link_clinical_to_genomic <- function(clinical_cohort_file, linkage_key_file, genomic_manifest_file) {
  
  message("Initiating Secure Linkage Protocol...")
  
  # 1. Load the Clinical Cohort (from TRE)
  # Input: A list of patients defined by clinical criteria (e.g., "Severe Crohn's")
  clinical_data <- fread(clinical_cohort_file) %>%
    select(patient_id, recruitment_site, diagnosis_date, phenotype_status)
  
  message(paste("Clinical Cohort Size:", nrow(clinical_data)))
  
  # 2. Load the Bridge File (The MPI)
  # This file is the "Key" - it maps internal Patient IDs to anonymized Sanger Sequencing IDs.
  # STRICT ACCESS CONTROL REQUIRED.
  bridge <- fread(linkage_key_file)
  
  # 3. Perform Linkage
  linked_cohort <- clinical_data %>%
    inner_join(bridge, by = "patient_id") %>%
    filter(!is.na(sanger_sample_id))
  
  message(paste("Successfully Linked Patients:", nrow(linked_cohort)))
  
  # 4. Check Genomic Availability (from HPC Manifest)
  # We verify if the physical genomic files (CRAM/VCF/PLINK) actually exist on the cluster.
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
  
  # 5. Filter for Valid Export
  # Only export patients who have BOTH clinical data AND high-quality sequence data
  valid_export <- final_export_list %>%
    filter(qc_pass == TRUE & (has_wes | has_snp)) %>%
    select(patient_id, sanger_sample_id, phenotype_status, has_wes, has_snp)
  
  message(paste("Final Validated Cohort for Export:", nrow(valid_export)))
  
  return(valid_export)
}

# --- Usage Example ---
# target_list <- link_clinical_to_genomic(
#   "requests/DAA102/clinical_cohort.csv",
#   "secure/MPI_July2022.csv",
#   "manifests/Sanger_Manifest_v4.csv"
# )
# write_csv(target_list, "outputs/DAA102_genomic_pull_list.csv")
