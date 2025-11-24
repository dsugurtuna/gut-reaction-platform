# API Documentation

## 📡 Gut Reaction Platform API Reference

This document provides comprehensive API documentation for all Gut Reaction Platform services.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Phenotype NLP Service](#phenotype-nlp-service)
- [Visual Governance Auditor](#visual-governance-auditor)
- [Clinical Ingestion Service](#clinical-ingestion-service)
- [Genomic Bridge Service](#genomic-bridge-service)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)

---

## Overview

### Base URLs

| Environment | Base URL |
|-------------|----------|
| Development | `http://localhost:8000` |
| Staging | `https://staging.gut-reaction.nhs.uk/api` |
| Production | `https://api.gut-reaction.nhs.uk` |

### API Versioning

APIs are versioned via URL path:
```
/api/v1/nlp/extract/vte
/api/v2/nlp/extract/vte
```

### Content Types

All requests should use:
```
Content-Type: application/json
Accept: application/json
```

---

## Authentication

### JWT Bearer Token

All API requests (except health checks) require authentication.

```http
Authorization: Bearer <your-jwt-token>
```

### Obtaining a Token

```http
POST /auth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&client_id=YOUR_CLIENT_ID&client_secret=YOUR_SECRET
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

---

## Phenotype NLP Service

Base path: `/api/v1/nlp`

### Health Check

```http
GET /api/v1/nlp/health
```

**Response:**
```json
{
  "status": "healthy",
  "model_version": "en_core_sci_lg-3.0",
  "uptime_seconds": 3600
}
```

---

### Extract VTE Phenotype

Extract Venous Thromboembolism (VTE) signals from clinical text.

```http
POST /api/v1/nlp/extract/vte
```

**Request Body:**
```json
{
  "patient_id": "P001",
  "encounter_id": "E001",
  "text_content": "Patient presents with acute pulmonary embolism in the left lung. History of DVT in 2019.",
  "metadata": {
    "source": "radiology",
    "date": "2024-01-15"
  }
}
```

**Response:**
```json
{
  "patient_id": "P001",
  "has_vte": true,
  "confidence": 0.95,
  "evidence": [
    "pulmonary embolism",
    "DVT"
  ],
  "context": {
    "negated_findings": [],
    "historical_findings": ["DVT in 2019"]
  },
  "processing_time_ms": 45
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Invalid request body |
| 401 | Unauthorized |
| 500 | Internal server error |

---

### Batch Processing

Submit multiple clinical notes for background processing.

```http
POST /api/v1/nlp/batch/process
```

**Request Body:**
```json
{
  "notes": [
    {
      "patient_id": "P001",
      "encounter_id": "E001",
      "text_content": "Clinical note text..."
    },
    {
      "patient_id": "P002",
      "encounter_id": "E002",
      "text_content": "Another clinical note..."
    }
  ],
  "callback_url": "https://your-system.com/webhook/nlp-results"
}
```

**Response:**
```json
{
  "job_id": "batch-abc123",
  "status": "queued",
  "note_count": 2,
  "estimated_completion_seconds": 30
}
```

---

### Get Batch Status

```http
GET /api/v1/nlp/batch/{job_id}/status
```

**Response:**
```json
{
  "job_id": "batch-abc123",
  "status": "completed",
  "progress": {
    "total": 100,
    "processed": 100,
    "failed": 2
  },
  "results_url": "/api/v1/nlp/batch/batch-abc123/results"
}
```

---

## Visual Governance Auditor

Base path: `/api/v1/audit`

### Audit Document

Upload a document for visual PII inspection.

```http
POST /api/v1/audit/document
Content-Type: multipart/form-data
```

**Request:**
```
file: <binary file data>
audit_level: strict  (optional: strict, standard, lenient)
```

**Response:**
```json
{
  "audit_id": "audit-xyz789",
  "filename": "patient_report.pdf",
  "pages_scanned": 5,
  "is_safe": false,
  "risk_score": 0.87,
  "detected_issues": [
    {
      "page": 1,
      "location": "top-left header",
      "type": "PATIENT_NAME",
      "description": "Unredacted patient name: 'Sarah Jones'",
      "confidence": 0.95
    },
    {
      "page": 3,
      "location": "footer",
      "type": "DOB",
      "description": "Date of birth visible: '12/05/1980'",
      "confidence": 0.92
    }
  ],
  "recommendation": "BLOCK - Document requires manual review",
  "processing_time_ms": 2850
}
```

---

### Batch Audit

```http
POST /api/v1/audit/batch
```

**Request Body:**
```json
{
  "documents": [
    {
      "document_id": "doc1",
      "url": "https://secure-storage.example.com/doc1.pdf"
    },
    {
      "document_id": "doc2", 
      "url": "https://secure-storage.example.com/doc2.pdf"
    }
  ],
  "callback_url": "https://your-system.com/webhook/audit-results"
}
```

**Response:**
```json
{
  "batch_id": "audit-batch-123",
  "status": "processing",
  "document_count": 2
}
```

---

### Get Audit History

```http
GET /api/v1/audit/history?start_date=2024-01-01&end_date=2024-01-31
```

**Response:**
```json
{
  "audits": [
    {
      "audit_id": "audit-xyz789",
      "timestamp": "2024-01-15T10:30:00Z",
      "filename": "report.pdf",
      "is_safe": false,
      "risk_score": 0.87,
      "reviewer": "ai-auditor"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 150
  }
}
```

---

## Clinical Ingestion Service

Base path: `/api/v1/clinical`

### Harmonize Trust Data

Trigger ETL processing for NHS Trust data.

```http
POST /api/v1/clinical/harmonize
```

**Request Body:**
```json
{
  "trust_id": "CAMBS",
  "input_file": "/data/clinical/CAMBS/2024-01-IBD-Medications.xlsx",
  "mapping_config": "default"
}
```

**Response:**
```json
{
  "job_id": "etl-456",
  "status": "processing",
  "trust_id": "CAMBS",
  "input_rows": 1500,
  "estimated_completion_seconds": 120
}
```

---

### Get Harmonization Status

```http
GET /api/v1/clinical/harmonize/{job_id}/status
```

**Response:**
```json
{
  "job_id": "etl-456",
  "status": "completed",
  "trust_id": "CAMBS",
  "metrics": {
    "input_rows": 1500,
    "output_rows": 1423,
    "dropped_rows": 77,
    "drop_reasons": {
      "invalid_date": 45,
      "non_target_drug": 32
    }
  },
  "output_file": "/data/harmonized/CAMBS_2024-01.csv"
}
```

---

## Genomic Bridge Service

Base path: `/api/v1/genomic`

### Link Clinical to Genomic

Create linkage between clinical cohort and genomic samples.

```http
POST /api/v1/genomic/link
```

**Request Body:**
```json
{
  "project_id": "DAA-2024-001",
  "clinical_cohort_file": "/data/cohorts/ibd_cases.csv",
  "required_data_types": ["WES", "SNP"]
}
```

**Response:**
```json
{
  "linkage_id": "link-789",
  "status": "completed",
  "project_id": "DAA-2024-001",
  "results": {
    "clinical_patients": 500,
    "linked_patients": 423,
    "match_rate": 0.846,
    "available_data": {
      "wes_available": 380,
      "snp_available": 412,
      "both_available": 367
    }
  },
  "output_manifest": "/outputs/DAA-2024-001_genomic_manifest.csv"
}
```

---

### Request Variant Extraction

Trigger VCF extraction for linked samples.

```http
POST /api/v1/genomic/extract
```

**Request Body:**
```json
{
  "project_id": "DAA-2024-001",
  "linkage_id": "link-789",
  "regions": [
    "chr6:32000000-33000000",
    "chr1:114000000-115000000"
  ],
  "output_format": "vcf.gz"
}
```

**Response:**
```json
{
  "extraction_id": "extract-101",
  "status": "queued",
  "slurm_job_id": "12345678",
  "estimated_completion_hours": 2
}
```

---

## Error Handling

### Error Response Format

All errors return a consistent JSON structure:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request body",
    "details": [
      {
        "field": "patient_id",
        "issue": "Field is required"
      }
    ],
    "request_id": "req-abc123",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

---

## Rate Limiting

### Limits

| Tier | Requests/Minute | Burst |
|------|-----------------|-------|
| Standard | 60 | 100 |
| Premium | 300 | 500 |
| Enterprise | Unlimited | - |

### Rate Limit Headers

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1705312800
```

### Handling Rate Limits

When rate limited, you'll receive:

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 30

{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests. Please retry after 30 seconds."
  }
}
```

---

## SDK Examples

### Python

```python
import requests

class GutReactionClient:
    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers["Authorization"] = f"Bearer {api_key}"
    
    def extract_vte(self, patient_id, text):
        response = self.session.post(
            f"{self.base_url}/api/v1/nlp/extract/vte",
            json={
                "patient_id": patient_id,
                "encounter_id": "auto",
                "text_content": text
            }
        )
        response.raise_for_status()
        return response.json()

# Usage
client = GutReactionClient("http://localhost:8000", "your-token")
result = client.extract_vte("P001", "Patient has pulmonary embolism")
print(result["has_vte"])  # True
```

### cURL

```bash
# Extract VTE
curl -X POST http://localhost:8001/extract/vte \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "patient_id": "P001",
    "encounter_id": "E001",
    "text_content": "Patient has acute PE"
  }'
```

---

## OpenAPI Specification

Interactive API documentation is available at:

- **Swagger UI**: `http://localhost:8001/docs`
- **ReDoc**: `http://localhost:8001/redoc`
- **OpenAPI JSON**: `http://localhost:8001/openapi.json`
