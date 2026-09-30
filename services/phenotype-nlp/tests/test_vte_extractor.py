"""Tests for VTEExtractor phenotype-nlp service.

The matcher and the negation window only use tokenisation, so the tests use a blank
English pipeline. That keeps them offline and independent of which spaCy model is installed.
"""

import pytest
import spacy

from vte_extractor import VTEExtractor, load_pipeline


@pytest.fixture(scope="module")
def extractor():
    return VTEExtractor(nlp=spacy.blank("en"))


class TestVTEExtractor:
    def test_positive_detection(self, extractor):
        results = extractor.process_batch(["Patient has a massive pulmonary embolism in the left lung."])
        assert len(results) == 1
        assert results[0]["status"] == "POSITIVE_VTE"

    def test_negated_finding(self, extractor):
        results = extractor.process_batch(["No evidence of PE or DVT."])
        assert len(results) == 1
        assert results[0]["status"] == "NEGATIVE_VTE"

    def test_no_mention(self, extractor):
        results = extractor.process_batch(["Patient presents with mild headache and fatigue."])
        assert results[0]["status"] == "NO_MENTION"
        assert results[0]["evidence"] is None

    def test_batch_processing(self, extractor):
        reports = [
            "Suspicion of deep vein thrombosis in the right leg.",
            "Lung fields are clear, no thrombus detected.",
            "Normal chest X-ray, no abnormalities.",
        ]
        results = extractor.process_batch(reports)
        assert [r["status"] for r in results] == ["POSITIVE_VTE", "NEGATIVE_VTE", "NO_MENTION"]

    def test_confidence_on_positive(self, extractor):
        results = extractor.process_batch(["CT scan reveals filling defect in the pulmonary artery."])
        assert results[0]["status"] == "POSITIVE_VTE"
        assert results[0]["confidence"] > 0

    def test_evidence_populated(self, extractor):
        results = extractor.process_batch(["Confirmed pulmonary embolism on CT angiography."])
        assert results[0]["status"] == "POSITIVE_VTE"
        assert results[0]["evidence"] == "pulmonary embolism"


class TestProcessClinicalText:
    """The single-note method used by the /extract/vte endpoint."""

    def test_positive_note(self, extractor):
        result = extractor.process_clinical_text("Patient has PE")
        assert result == {
            "status": "POSITIVE_VTE",
            "has_vte": True,
            "confidence_score": 0.95,
            "extracted_terms": ["PE"],
        }

    def test_negated_note(self, extractor):
        result = extractor.process_clinical_text("CT ruled out pulmonary embolism.")
        assert result["status"] == "NEGATIVE_VTE"
        assert result["has_vte"] is False
        assert result["confidence_score"] == 0.0
        assert result["extracted_terms"] == []

    def test_no_mention_note(self, extractor):
        result = extractor.process_clinical_text("Routine follow-up, no concerns.")
        assert result["status"] == "NO_MENTION"
        assert result["has_vte"] is False

    def test_repeated_term_reported_once(self, extractor):
        result = extractor.process_clinical_text("DVT in the left leg. DVT also in the right leg.")
        assert result["extracted_terms"] == ["DVT"]


class TestNegation:
    def test_ruled_out(self, extractor):
        doc = extractor.nlp("CT ruled out pulmonary embolism.")
        matches = extractor.matcher(doc)
        assert matches
        for _, start, end in matches:
            span = doc[start:end]
            assert extractor._is_negated(span, doc)

    def test_no_negation_present(self, extractor):
        doc = extractor.nlp("Large pulmonary embolism found.")
        matches = extractor.matcher(doc)
        assert matches
        for _, start, end in matches:
            span = doc[start:end]
            assert not extractor._is_negated(span, doc)


class TestMatcherSetup:
    def test_terms_loaded(self, extractor):
        assert len(extractor.terms) == 9
        assert "pulmonary embolism" in extractor.terms
        assert "dvt" in extractor.terms


class TestPipelineLoading:
    def test_falls_back_when_model_missing(self):
        nlp, name = load_pipeline("model_that_is_not_installed")
        assert name in ("en_core_web_sm", "blank:en")
        assert nlp.lang == "en"
