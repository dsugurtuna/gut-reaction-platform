from __future__ import annotations

import logging
import re
from typing import Any

import spacy
from spacy.language import Language
from spacy.matcher import PhraseMatcher
from spacy.tokens import Doc, Span

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger("NLP_Pipeline")

# Placeholder score returned for a positive finding. It is a constant, not a
# calibrated probability: the extractor is rule-based and has not been evaluated
# against an annotated reference set.
POSITIVE_CONFIDENCE = 0.95

# Cue phrases that negate a VTE mention when they appear in the six tokens before it.
NEGATION_TRIGGERS = [
    "no",
    "not",
    "negative for",
    "free of",
    "ruled out",
    "absence of",
    "no evidence of",
    "unlikely",
    "doubtful",
]
_NEGATION_PATTERN = re.compile(r"\b(?:" + "|".join(re.escape(t) for t in NEGATION_TRIGGERS) + r")\b")


def load_pipeline(model_name: str) -> tuple[Language, str]:
    """Load a spaCy pipeline, falling back to smaller ones when a model is not installed.

    Order: the requested model (for example the SciSpacy ``en_core_sci_md``), then
    ``en_core_web_sm``, then a blank English tokenizer. The phrase matcher and the
    negation window only use tokenisation, so every option gives the same matches.
    Returns the pipeline and the name of what was actually loaded.
    """
    for candidate in dict.fromkeys([model_name, "en_core_web_sm"]):
        try:
            return spacy.load(candidate), candidate
        except OSError:
            logger.warning("spaCy model %s is not installed; trying the next fallback.", candidate)
    logger.warning("No spaCy model installed; using a blank English tokenizer.")
    return spacy.blank("en"), "blank:en"


class VTEExtractor:
    """Rule-based extractor for venous thromboembolism (VTE) mentions in free-text reports.

    How it works:
    - A spaCy PhraseMatcher finds nine VTE terms (case-insensitive).
    - A mention is treated as negated if a cue such as "no" or "ruled out" appears,
      as a whole word, in the six tokens before it (a simplified NegEx-style window).
    - The result is a document-level flag with the matched terms as evidence.

    It does not use a trained model for classification. Loading SciSpacy is optional
    and only affects tokenisation.
    """

    def __init__(self, model_name: str = "en_core_sci_md", nlp: Language | None = None):
        if nlp is not None:
            self.nlp = nlp
            self.model_name = f"{nlp.meta.get('lang', 'xx')}_{nlp.meta.get('name', 'custom')}"
        else:
            logger.info("Initialising NLP pipeline, requested model: %s", model_name)
            self.nlp, self.model_name = load_pipeline(model_name)
        logger.info("Using spaCy pipeline: %s", self.model_name)
        self._setup_matcher()

    def _setup_matcher(self) -> None:
        """Configure the PhraseMatcher with the VTE term list."""
        self.matcher = PhraseMatcher(self.nlp.vocab, attr="LOWER")
        self.terms = [
            "pulmonary embolism",
            "pe",
            "dvt",
            "deep vein thrombosis",
            "thrombus",
            "clot",
            "embolus",
            "venous thrombosis",
            "filling defect",
        ]
        self.patterns = [self.nlp.make_doc(text) for text in self.terms]
        self.matcher.add("VTE_TERMS", self.patterns)
        logger.info("Loaded %d VTE terms.", len(self.terms))

    def process_batch(self, reports: list[str]) -> list[dict[str, Any]]:
        """Analyse several reports, streaming them through ``nlp.pipe``."""
        return [self._analyze_doc(doc) for doc in self.nlp.pipe(reports, batch_size=50)]

    def process_clinical_text(self, text: str) -> dict[str, Any]:
        """Analyse one report and return the fields used by the HTTP API."""
        result = self._analyze_doc(self.nlp(text))
        return {
            "status": result["status"],
            "has_vte": result["status"] == "POSITIVE_VTE",
            "confidence_score": result.get("confidence", 0.0),
            "extracted_terms": result["terms"],
        }

    def _analyze_doc(self, doc: Doc) -> dict[str, Any]:
        """Match VTE terms and drop the negated ones."""
        matches = self.matcher(doc)

        if not matches:
            return {"status": "NO_MENTION", "evidence": None, "terms": []}

        positive_terms: list[str] = []
        for _match_id, start, end in matches:
            span = doc[start:end]
            if self._is_negated(span, doc):
                continue
            if span.text not in positive_terms:
                positive_terms.append(span.text)

        if positive_terms:
            return {
                "status": "POSITIVE_VTE",
                "evidence": "; ".join(positive_terms),
                "terms": positive_terms,
                "confidence": POSITIVE_CONFIDENCE,
            }

        return {"status": "NEGATIVE_VTE", "evidence": "Negated findings only", "terms": []}

    def _is_negated(self, span: Span, doc: Doc) -> bool:
        """Return True if a negation cue appears as a whole word in the six tokens before the span.

        Known limits: cues after the term ("PE unlikely") are missed, and the window
        can cross sentence boundaries.
        """
        window_start = max(0, span.start - 6)
        window_text = doc[window_start : span.start].text.lower()
        return _NEGATION_PATTERN.search(window_text) is not None


if __name__ == "__main__":
    import json

    extractor = VTEExtractor()

    test_batch = [
        "Patient has a massive pulmonary embolism in the left lung.",
        "Lung fields are clear. No evidence of PE or DVT.",
        "CT scan shows no sign of thrombus.",
        "Suspicion of deep vein thrombosis in the right leg.",
    ]

    print(json.dumps(extractor.process_batch(test_batch), indent=2))
