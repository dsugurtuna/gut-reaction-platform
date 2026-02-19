from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional
import logging
from vte_extractor import VTEExtractor as VTEPhenotypeExtractor

# --- Configuration ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Phenotype NLP Service",
    description="Extracts clinical phenotypes (VTE, IBD severity) from unstructured text.",
    version="2.0.0",
)


# --- Models ---
class ClinicalNote(BaseModel):
    patient_id: str
    encounter_id: str
    text_content: str
    metadata: Optional[dict] = None


class PhenotypeResponse(BaseModel):
    patient_id: str
    has_vte: bool
    confidence: float
    evidence: List[str]


# --- Dependencies ---
# Initialize the extractor (Singleton pattern)
extractor = VTEPhenotypeExtractor()

# --- Endpoints ---


@app.get("/health")
async def health_check():
    return {"status": "healthy", "model_version": "en_core_sci_lg-3.0"}


@app.post("/extract/vte", response_model=PhenotypeResponse)
async def extract_vte(note: ClinicalNote):
    """
    Analyze a clinical note for Venous Thromboembolism (VTE) signals.
    """
    logger.info(f"Processing note for patient {note.patient_id}")

    try:
        # In a real scenario, this would be async or offloaded to Celery
        result = extractor.process_clinical_text(note.text_content)

        return PhenotypeResponse(
            patient_id=note.patient_id,
            has_vte=result["has_vte"],
            confidence=result["confidence_score"],
            evidence=result["extracted_terms"],
        )
    except Exception as e:
        logger.error(f"Error processing note: {str(e)}")
        raise HTTPException(status_code=500, detail="NLP Processing Failed")


@app.post("/batch/process")
async def batch_process(notes: List[ClinicalNote], background_tasks: BackgroundTasks):
    """
    Submit a batch of notes for background processing.
    """
    background_tasks.add_task(process_batch_job, notes)
    return {"message": "Batch received", "count": len(notes)}


def process_batch_job(notes: List[ClinicalNote]):
    logger.info(f"Starting batch job for {len(notes)} notes...")
    # Logic to process and save to DB would go here
    pass
