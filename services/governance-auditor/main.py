import logging
import os
import shutil
import tempfile
from pathlib import Path
from typing import Annotated

from fastapi import FastAPI, File, HTTPException, UploadFile
from pydantic import BaseModel

from visual_pii_auditor import VisualPIIAuditor

# --- Configuration ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Visual Governance Auditor",
    description="Visual inspection of redacted documents for PII leakage. The VLM call is mocked.",
    version="1.0.0",
)

auditor = VisualPIIAuditor()


class AuditResponse(BaseModel):
    filename: str
    is_safe: bool
    risk_score: float
    detected_issues: list[str]
    reasoning: str
    mocked: bool


@app.get("/health")
async def health_check():
    return {"status": "healthy", "vlm_model": auditor.model.value, "vlm_mocked": auditor.MOCKED}


@app.post("/audit/document", response_model=AuditResponse)
async def audit_document(file: Annotated[UploadFile, File()]):
    """Upload a PDF or image page to be checked for visible PII."""
    filename = file.filename or "upload"
    # Never build a path from the client's filename: keep only its extension.
    suffix = Path(filename).suffix[:10]
    fd, temp_path = tempfile.mkstemp(suffix=suffix)

    try:
        with os.fdopen(fd, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        logger.info("Auditing uploaded file (%s)", suffix or "no extension")
        result = auditor.audit_document(temp_path)
    except Exception:
        logger.exception("Audit failed")
        raise HTTPException(status_code=500, detail="Visual Audit Failed")
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    return AuditResponse(
        filename=filename,
        is_safe=result.is_safe,
        risk_score=result.risk_score,
        detected_issues=result.detected_pii,
        reasoning=result.reasoning,
        mocked=auditor.MOCKED,
    )
