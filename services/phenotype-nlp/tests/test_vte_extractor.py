"""Tests for VTEExtractor phenotype-nlp service."""

import pytest

from vte_extractor import VTEExtractor


@pytest.fixture(scope="module")
def extractor():
    """Initialise VTEExtractor once for all tests (falls back to en_core_web_sm)."""
    return VTEExtractor(model_name="en_core_web_sm")


class TestVTEExtractor:
    def test_positive_detection(self, extractor):
        results = extractor.process_batch(["Patient has a massive pulmonary embolism in the left lung."])
        assert len(results) == 1
        assert results[0]["status"] == "POSITIVE_VTE"

    def test_negated_finding(self, extractor):
        results = extractor.process_batch(["No evidence of PE or DVT."])
        assert len(results) == 1
        assert results[0]["status"] in ("NEGATIVE_VTE", "NO_MENTION")

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
        assert len(results) == 3

    def test_confidence_on_positive(self, extractor):
        results = extractor.process_batch(["CT scan reveals filling defect in the pulmonary artery."])
        if results[0]["status"] == "POSITIVE_VTE":
            assert "confidence" in results[0]
            assert results[0]["confidence"] > 0

    def test_evidence_populated(self, extractor):
        results = extractor.process_batch(["Confirmed pulmonary embolism on CT angiography."])
        if results[0]["status"] == "POSITIVE_VTE":
            assert results[0]["evidence"] is not None
            assert len(results[0]["evidence"]) > 0


class TestNegation:
    def test_ruled_out(self, extractor):
        doc = extractor.nlp("CT ruled out pulmonary embolism.")
        matches = extractor.matcher(doc)
        for _, start, end in matches:
            span = doc[start:end]
            assert extractor._is_negated(span, doc)

    def test_no_negation_present(self, extractor):
        doc = extractor.nlp("Large pulmonary embolism found.")
        matches = extractor.matcher(doc)
        for _, start, end in matches:
            span = doc[start:end]
            assert not extractor._is_negated(span, doc)


class TestMatcherSetup:
    def test_terms_loaded(self, extractor):
        assert len(extractor.terms) == 9
        assert "pulmonary embolism" in extractor.terms
        assert "dvt" in extractor.terms
