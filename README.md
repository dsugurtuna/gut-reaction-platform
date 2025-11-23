# Gut Reaction Platform: Secure Multi-Modal Health Data Environment

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/dsugurtuna/gut-reaction-platform)
[![Architecture](https://img.shields.io/badge/architecture-microservices-blue)](https://github.com/dsugurtuna/gut-reaction-platform)
[![Compliance](https://img.shields.io/badge/compliance-NHS_Five_Safes-orange)](https://github.com/dsugurtuna/gut-reaction-platform)

**Technical Project Lead:** Ugur Tuna  
**Domain:** IBD Research, Genomics, Clinical Informatics, AI Governance

---

## 🚀 Executive Summary

The **Gut Reaction Platform** is an enterprise-grade, federated data infrastructure designed to bridge the gap between clinical phenotypes (NHS Trusts) and genomic assets (Sanger Institute). 

Unlike traditional siloed scripts, this platform employs a **Microservices Architecture** to ensure scalability, security, and auditability. It features a cutting-edge **Visual AI Governance** module that uses Vision-Language Models (VLMs) to automate the "Four Eyes" review process for data release.

## 🏗 System Architecture

The platform is composed of four isolated microservices orchestrated via Docker Compose (local) and Kubernetes (production):

| Service | Tech Stack | Responsibility |
|---------|------------|----------------|
| **Clinical Ingestion** | R, Plumber, Tidyverse | Harmonizes raw Trust data to OMOP CDM standards. |
| **Phenotype NLP** | Python, FastAPI, Spacy | Extracts unstructured clinical features (VTE, Severity). |
| **Genomic Bridge** | R, Bioconductor | Securely links clinical IDs to HPC genomic assets across the air gap. |
| **Visual Auditor** | Python, PyTorch, LLaVA | **[NEW]** AI-driven visual inspection of redacted PDFs for PII leakage. |

👉 **[View Full Architecture Diagram](docs/ARCHITECTURE.md)**

## 🌟 Key Features

### 1. AI-Driven Visual Governance
Automating the "Five Safes" framework. The `governance-auditor` service uses a Vision-Language Model to "look" at redacted documents just like a human auditor would, catching pixelation errors that regex-based tools miss.

### 2. Secure "Air Gap" Linkage
The `genomic-bridge` service implements a Zero-Trust protocol. Clinical data never leaves the Trusted Research Environment (TRE). Only opaque, de-identified tokens are exchanged with the High Performance Computing (HPC) cluster.

### 3. Enterprise Engineering Standards
- **Infrastructure as Code:** Dockerized services with defined `docker-compose.yml`.
- **Defensive Programming:** `checkmate` assertions in R and Pydantic validation in Python.
- **Observability:** Structured logging and audit trails for all data access.

## 🛠 Deployment

### Prerequisites
- Docker & Docker Compose
- Python 3.9+
- R 4.2+

### Quick Start
```bash
# 1. Clone the repository
git clone https://github.com/dsugurtuna/gut-reaction-platform.git

# 2. Launch the stack
docker-compose up --build

# 3. Access the Dashboard
# Navigate to http://localhost:3000
```

## 📚 Documentation

- [System Architecture](docs/ARCHITECTURE.md)
- [API Documentation (Swagger)](http://localhost:8001/docs)
- [Governance Protocol](docs/GOVERNANCE.md)

---
*Built to demonstrate Senior Technical Leadership in Health Data Science.*


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
