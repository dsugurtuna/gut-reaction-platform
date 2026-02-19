"""Tests for VisualPIIAuditor governance-auditor service."""

import json
import pytest

from visual_pii_auditor import VisualPIIAuditor, AuditResult, VLMProvider


@pytest.fixture
def auditor():
    """Create auditor in mock mode (no API key)."""
    return VisualPIIAuditor(api_key="mock_key")


class TestVisualPIIAuditor:
    def test_audit_returns_result(self, auditor):
        result = auditor.audit_document("fake_image.png")
        assert isinstance(result, AuditResult)

    def test_mock_result_is_unsafe(self, auditor):
        result = auditor.audit_document("fake_image.png")
        assert result.is_safe is False
        assert result.risk_score > 0.5

    def test_detected_pii_not_empty(self, auditor):
        result = auditor.audit_document("fake_image.png")
        assert len(result.detected_pii) > 0

    def test_reasoning_populated(self, auditor):
        result = auditor.audit_document("fake_image.png")
        assert len(result.reasoning) > 0

    def test_encode_image(self, auditor):
        encoded = auditor._encode_image("test.png")
        assert isinstance(encoded, str)
        assert len(encoded) > 0

    def test_audit_prompt_content(self, auditor):
        prompt = auditor._get_audit_prompt()
        assert "PII" in prompt
        assert "NHS" in prompt
        assert "redaction" in prompt.lower()


class TestVLMProvider:
    def test_openai_provider(self):
        assert VLMProvider.OPENAI_GPT4V.value == "gpt-4-vision-preview"

    def test_llava_provider(self):
        assert VLMProvider.LLAVA_NEXT.value == "llava-v1.6-34b"


class TestResponseParsing:
    def test_parse_valid_response(self):
        auditor = VisualPIIAuditor(api_key="mock")
        response = {
            "choices": [{
                "message": {
                    "content": json.dumps({
                        "is_safe": True,
                        "risk_score": 0.1,
                        "detected_pii": [],
                        "reasoning": "Document is clean.",
                    })
                }
            }]
        }
        result = auditor._parse_vlm_response(response)
        assert result.is_safe is True
        assert result.risk_score == 0.1
        assert result.detected_pii == []

    def test_parse_malformed_response(self):
        auditor = VisualPIIAuditor(api_key="mock")
        result = auditor._parse_vlm_response({"bad": "data"})
        assert isinstance(result, AuditResult)
        assert result.is_safe is False
