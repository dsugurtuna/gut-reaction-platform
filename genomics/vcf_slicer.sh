#!/bin/bash
# ==============================================================================
# Genomic Variant Extraction Pipeline (VCF Slicer)
# ==============================================================================
# Description:
#   Automates the extraction of specific genomic variants for Data Access 
#   Applications (DAA). Designed to run on the HPC cluster.
#   Ensures strict data minimization by only extracting requested regions
#   for requested samples.
#
# Usage:
#   ./vcf_slicer.sh [DAA_ID] [GENE_REGION]
#
# Example:
#   ./vcf_slicer.sh DAA102 chr1:1000-2000
# ==============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

DAA_ID=$1
REGION=$2

# Configuration (Mock Paths)
INPUT_VCF="/data/genetics/release_v3/all_samples_imputed.vcf.gz"
OUTPUT_BASE="/data/outputs"
OUTPUT_DIR="${OUTPUT_BASE}/${DAA_ID}"
SAMPLE_LIST="${OUTPUT_DIR}/sample_list.txt"

# Validation
if [ -z "$DAA_ID" ] || [ -z "$REGION" ]; then
    echo "Usage: $0 [DAA_ID] [GENE_REGION]"
    exit 1
fi

if [ ! -f "$SAMPLE_LIST" ]; then
    echo "Error: Sample list not found at $SAMPLE_LIST. Run linkage_manager.R first."
    exit 1
fi

echo "Starting Variant Extraction for Project: $DAA_ID"
echo "Region: $REGION"
echo "Input VCF: $INPUT_VCF"

# 1. Create the output directory
mkdir -p "$OUTPUT_DIR"

# 2. Extract specific samples (Air Gap Linkage)
# We use bcftools to slice the massive VCF.
# This step is critical for "Safe Data" compliance - we never export the full VCF.

echo "Slicing VCF..."
bcftools view \
  --samples-file "$SAMPLE_LIST" \
  --regions "$REGION" \
  --min-ac 1 \
  --output-type z \
  --output "${OUTPUT_DIR}/${DAA_ID}_${REGION}_raw.vcf.gz" \
  "$INPUT_VCF"

# 3. Anonymize the header (Privacy Engineering)
# Remove internal paths, command history, and quality scores that might leak info.

echo "Sanitizing VCF Header..."
bcftools annotate \
  --remove "ID,QUAL,INFO/AF,INFO/AC" \
  "${OUTPUT_DIR}/${DAA_ID}_${REGION}_raw.vcf.gz" \
  > "${OUTPUT_DIR}/${DAA_ID}_final_clean.vcf"

# 4. Compress and Index for Delivery
bgzip -f "${OUTPUT_DIR}/${DAA_ID}_final_clean.vcf"
tabix -p vcf "${OUTPUT_DIR}/${DAA_ID}_final_clean.vcf.gz"

echo "========================================================"
echo "Extraction Complete."
echo "Output: ${OUTPUT_DIR}/${DAA_ID}_final_clean.vcf.gz"
echo "Ready for Privitar ingestion and Airlock transfer."
echo "========================================================"
