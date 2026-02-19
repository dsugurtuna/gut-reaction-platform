from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List
import logging
import shutil
import os
from visual_pii_auditor import VisualPIIAuditor

# --- Configuration ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Visual Governance Auditor",
    description="AI-powered visual inspection of redacted documents for PII leakage.",
    version="1.0.0",
)

auditor = VisualPIIAuditor()


class AuditResult(BaseModel):
    filename: str
    is_safe: bool
    risk_score: float
    detected_issues: List[str]


@app.post("/audit/document", response_model=AuditResult)
async def audit_document(file: UploadFile = File(...)):
    """
    Upload a PDF/Image to be visually scanned by the VLM for PII.
    """
    temp_path = f"/tmp/{file.filename}"

    try:
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        logger.info(f"Auditing file: {file.filename}")

        # Run the VLM check
        report = auditor.audit_document(temp_path)

        return AuditResult(
            filename=file.filename,
            is_safe=report["status"] == "PASS",
            risk_score=report.get("confidence_score", 0.0),
            detected_issues=report.get("flags", []),
        )

    except Exception as e:
        logger.error(f"Audit failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Visual Audit Failed")
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)
