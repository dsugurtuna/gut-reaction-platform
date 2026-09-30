"""HTTP-level tests for the phenotype-nlp FastAPI app.

These call the same endpoints as the Docker integration job in CI, without Docker.
"""

import os

# Use a blank English tokenizer so the tests do not depend on a downloaded model.
os.environ.setdefault("MODEL_PATH", "blank:en")

import pytest
from fastapi.testclient import TestClient

import main


@pytest.fixture(scope="module")
def client():
    return TestClient(main.app)


def test_health_reports_loaded_pipeline(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "healthy"
    assert body["spacy_pipeline"] == main.extractor.model_name


def test_extract_vte_positive(client):
    payload = {"patient_id": "test", "encounter_id": "e1", "text_content": "Patient has PE"}
    response = client.post("/extract/vte", json=payload)
    assert response.status_code == 200
    assert response.json() == {
        "patient_id": "test",
        "status": "POSITIVE_VTE",
        "has_vte": True,
        "confidence": 0.95,
        "evidence": ["PE"],
    }


def test_extract_vte_negated(client):
    payload = {"patient_id": "p2", "encounter_id": "e2", "text_content": "No evidence of DVT."}
    response = client.post("/extract/vte", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "NEGATIVE_VTE"
    assert body["has_vte"] is False
    assert body["evidence"] == []


def test_extract_vte_rejects_missing_fields(client):
    response = client.post("/extract/vte", json={"patient_id": "p3"})
    assert response.status_code == 422


def test_batch_process_accepts_notes(client):
    notes = [
        {"patient_id": "a", "encounter_id": "1", "text_content": "Pulmonary embolism confirmed."},
        {"patient_id": "b", "encounter_id": "2", "text_content": "No thrombus seen."},
    ]
    response = client.post("/batch/process", json=notes)
    assert response.status_code == 200
    assert response.json() == {"message": "Batch received", "count": 2}


def test_batch_job_counts_statuses():
    notes = [
        main.ClinicalNote(patient_id="a", encounter_id="1", text_content="Pulmonary embolism confirmed."),
        main.ClinicalNote(patient_id="b", encounter_id="2", text_content="No thrombus seen."),
        main.ClinicalNote(patient_id="c", encounter_id="3", text_content="Headache."),
    ]
    summary = main.process_batch_job(notes)
    assert summary == {"POSITIVE_VTE": 1, "NEGATIVE_VTE": 1, "NO_MENTION": 1}
