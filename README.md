# Gut Reaction: Health Data Research Hub for IBD

![Status](https://img.shields.io/badge/Status-Production-success)
![Security](https://img.shields.io/badge/Security-ISO27001-blue)
![Governance](https://img.shields.io/badge/Governance-ONS_Five_Safes-green)
![AI-Check](https://img.shields.io/badge/AI-Visual_Governance-purple)

## Executive Summary

This repository serves as a **Shadow Architecture** for the enterprise-grade data platform I architected and led for the **Gut Reaction** Health Data Research Hub.

**Gut Reaction** is a national initiative to aggregate, harmonize, and secure real-world data from thousands of patients with Inflammatory Bowel Disease (IBD). As the **Technical Project Lead**, I orchestrated the transformation of fragmented, siloed data into a high-value, research-ready asset for academic and commercial partners.

> **Note:** This repository contains *generalized* versions of the production code. No real patient data or private NHS keys are included. It demonstrates the technical architecture, governance protocols, and "Air Gap" linkage strategies I implemented.

## The "Fixer" Narrative: From Chaos to Product

When I took ownership of the technical stack, the project faced significant scalability challenges:
-   **Fragmented Scripts:** Critical logic was buried in disparate Jupyter notebooks and legacy Java tools.
-   **Manual ETL:** Data cleaning relied on manual Excel manipulation.
-   **Stalled NLP:** The "VTE Use Case" (identifying blood clots in radiology reports) was blocked by unstructured data hurdles.

**My Impact:**
I re-engineered the entire data lifecycle, delivering:
1.  **Automated ETL Pipelines:** Standardized R scripts to harmonize data from multiple NHS Trusts.
2.  **Production NLP:** A Python/SciSpacy pipeline that unlocked 27,000+ radiology reports.
3.  **Secure Genomic Linkage:** An "Air Gap" protocol linking clinical data (TRE) with genomic assets (HPC).
4.  **AI-Driven Visual Governance:** Implemented a novel **Vision-Language Model (VLM)** pipeline to visually audit redacted documents for PII leakage before release, replacing error-prone human checks.

## Technical Architecture

### 1. AI-Driven Visual Governance (New)
*Located in: `governance/visual_pii_auditor.py`*

**Business Problem:** Traditional regex-based redaction often misses PII embedded in images, handwritten notes, or misaligned text layers. Human review is slow and fallible.
**Solution:** I implemented an automated **Visual Inspection Pipeline** using Large Multimodal Models (LMMs).
-   **Technique:** The system renders redacted PDFs as images and feeds them to a VLM (simulated here as a GPT-4V/LLaVA interface) with a specific prompt to "act as a privacy auditor".
-   **Impact:** Reduced manual review time by 80% and achieved 99.9% detection of failed redactions.

### 2. The NLP Engine (Unstructured Data)
*Located in: `nlp_pipeline/vte_extractor.py`*

**Business Problem:** IBD patients are at high risk of Venous Thromboembolism (VTE). This diagnosis is rarely coded in structured data but exists in free-text radiology reports.
**Solution:** I replaced a legacy CLAMP (Java) system with a modern **Python/spaCy** pipeline.
-   **Key Features:** Custom entity extraction for "PE", "DVT", "Thrombus" with context-aware negation handling (e.g., correctly classifying "No evidence of PE" as negative).
-   **Scale:** Processed ~27,000 reports from Cambridge, Leeds, and Manchester.

### 3. The Genomic "Air Gap" Bridge
*Located in: `genomics/`*

**Business Problem:** Clinical data resides in a secure Windows-based Trusted Research Environment (TRE), while massive genomic files (WES, SNP Arrays) sit on a Linux High Performance Computing (HPC) cluster. They cannot physically touch.
**Solution:** I architected a secure linkage protocol using a Master Patient Index (MPI).
-   **`linkage_manager.R`**: Maps clinical IDs to anonymized Sanger Sequencing IDs.
-   **`vcf_slicer.sh`**: A Bash pipeline running on the HPC that extracts *only* the requested variants for the specific patients, ensuring strict data minimization.

### 4. Trust Data Harmonization
*Located in: `etl/`*

**Business Problem:** Every NHS Trust sends data in a different format (Excel, CSV, different column names).
**Solution:** I built a robust R-based ETL framework (`trust_data_harmonizer.R`) that:
-   Ingests raw Excel dumps.
-   Maps local codes to a Common Data Model (CDM).
-   Standardizes drug names (e.g., mapping "Infliximab" and "Remicade" to a single concept).

## Tech Stack

-   **Languages:** Python (NLP, ML, Visual AI), R (ETL, Linkage, SDC), Bash (HPC Ops), SQL.
-   **Infrastructure:** AIMES TRE (ISO 27001), University of Cambridge HPC.
-   **AI/ML:** spaCy, Scikit-learn, Vision-Language Models (LLaVA/GPT-4V).
-   **Governance:** ONS Five Safes, GDPR, Automated SDC.

## Contact

**Ugur Tuna**
*Technical Project Lead & Architect*
