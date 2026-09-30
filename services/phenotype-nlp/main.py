import logging
import os
from collections import Counter

from fastapi import BackgroundTasks, FastAPI, HTTPException
from pydantic import BaseModel

from vte_extractor import VTEExtractor

# --- Configuration ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Phenotype NLP Service",
    description="Flags venous thromboembolism (VTE) mentions in free-text reports using rules and negation cues.",
    version="2.0.0",
)


# --- Models ---
class ClinicalNote(BaseModel):
    patient_id: str
    encounter_id: str
    text_content: str
    metadata: dict | None = None


class PhenotypeResponse(BaseModel):
    patient_id: str
    status: str
    has_vte: bool
    confidence: float
    evidence: list[str]


# --- Dependencies ---
# One extractor per process. MODEL_PATH may name an installed spaCy package or a
# model directory; if it cannot be loaded the extractor falls back (see vte_extractor).
extractor = VTEExtractor(model_name=os.getenv("MODEL_PATH", "en_core_sci_md"))


# --- Endpoints ---
@app.get("/health")
async def health_check():
    return {"status": "healthy", "spacy_pipeline": extractor.model_name}


@app.post("/extract/vte", response_model=PhenotypeResponse)
async def extract_vte(note: ClinicalNote):
    """Analyse one clinical note for VTE mentions."""
    # Log size only: identifiers and note text stay out of the logs.
    logger.info("Processing note (%d characters)", len(note.text_content))

    try:
        result = extractor.process_clinical_text(note.text_content)
    except Exception:
        logger.exception("Error processing note")
        raise HTTPException(status_code=500, detail="NLP Processing Failed")

    return PhenotypeResponse(
        patient_id=note.patient_id,
        status=result["status"],
        has_vte=result["has_vte"],
        confidence=result["confidence_score"],
        evidence=result["extracted_terms"],
    )


@app.post("/batch/process")
async def batch_process(notes: list[ClinicalNote], background_tasks: BackgroundTasks):
    """Accept a batch of notes and analyse them after the response is sent.

    Results are only logged as counts; there is no persistence layer yet.
    """
    background_tasks.add_task(process_batch_job, notes)
    return {"message": "Batch received", "count": len(notes)}


def process_batch_job(notes: list[ClinicalNote]) -> Counter:
    logger.info("Starting batch job for %d notes...", len(notes))
    results = extractor.process_batch([note.text_content for note in notes])
    summary = Counter(result["status"] for result in results)
    logger.info("Batch job finished: %s", dict(summary))
    return summary
