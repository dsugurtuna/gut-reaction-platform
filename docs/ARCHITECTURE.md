# System Architecture: Gut Reaction Platform

## Overview
The Gut Reaction Platform is a secure, federated data environment designed to integrate clinical phenotypes from NHS Trusts with genomic data (WES, GWAS) stored in High Performance Computing (HPC) environments.

## High-Level Design

```mermaid
graph TD
    User[Researcher / Data Steward] -->|HTTPS/TLS| Gateway[API Gateway (Nginx)]
    
    subgraph "Trusted Research Environment (TRE)"
        Gateway --> UI[Dashboard (React)]
        Gateway --> Auth[Identity Provider (Keycloak)]
        
        subgraph "Clinical Zone"
            Ingest[Clinical Ingestion Service (R)] -->|OMOP Mapping| DB[(Clinical DB - Postgres)]
            NLP[Phenotype NLP Service (Python)] -->|Extract VTE/IBD| DB
        end
        
        subgraph "Governance Zone"
            Auditor[Visual Governance Auditor (Python/VLM)] -->|Audit PDFs| Logs[(Audit Logs)]
        end
    end
    
    subgraph "Air Gap Bridge"
        Linker[Genomic Bridge Service (R)]
        DB -->|De-identified IDs| Linker
    end
    
    subgraph "HPC Environment"
        Linker -->|Query Manifest| Storage[Genomic Data Lake (CRAM/VCF)]
        Storage -->|Compute| Slurm[Slurm Workload Manager]
    end
```

## Core Components

### 1. Clinical Ingestion Service (R)
- **Role:** ETL pipeline to harmonize raw NHS Trust extracts into the OMOP Common Data Model.
- **Tech:** R, Tidyverse, Plumber, Checkmate.
- **Key Feature:** "Five Safes" compliant data validation.

### 2. Phenotype NLP Service (Python)
- **Role:** Extracts deep phenotypic data (e.g., disease severity, VTE history) from unstructured clinical notes.
- **Tech:** Python, FastAPI, Spacy (SciSpacy), Transformers.
- **Key Feature:** Enterprise-grade logging and async batch processing.

### 3. Visual Governance Auditor (Python)
- **Role:** AI-driven "Four Eyes" review. Uses Vision-Language Models (VLM) to visually inspect redacted documents before release.
- **Tech:** Python, PyTorch, LLaVA/GPT-4V Mock.
- **Key Feature:** Prevents pixelation errors where PII might still be visible.

### 4. Genomic Bridge Service (R)
- **Role:** Manages the linkage between clinical IDs and genomic sample IDs across the secure air gap.
- **Tech:** R, Bioconductor.
- **Key Feature:** Zero-trust linkage; clinical data never leaves the TRE, only de-identified IDs cross the bridge.

## Security & Compliance
- **Audit Trails:** All data access is logged to an immutable audit log.
- **Containerization:** All services run in isolated Docker containers.
- **Network Policies:** Kubernetes NetworkPolicies restrict traffic between zones.
