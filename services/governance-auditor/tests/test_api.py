"""HTTP-level tests for the governance-auditor FastAPI app."""

import pytest
from fastapi.testclient import TestClient

import main


@pytest.fixture(scope="module")
def client():
    return TestClient(main.app)


def test_health_says_the_model_call_is_mocked(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "vlm_model": "gpt-4-vision-preview", "vlm_mocked": True}


def test_audit_document_returns_canned_mock_result(client):
    files = {"file": ("page1.png", b"not really an image", "image/png")}
    response = client.post("/audit/document", files=files)
    assert response.status_code == 200
    body = response.json()
    assert body["filename"] == "page1.png"
    assert body["is_safe"] is False
    assert body["risk_score"] == 0.95
    assert len(body["detected_issues"]) == 2
    assert body["mocked"] is True


def test_upload_filename_is_not_used_as_a_path(client, tmp_path, monkeypatch):
    seen = {}

    def fake_audit(path):
        seen["path"] = path
        return main.auditor._parse_vlm_response({})

    monkeypatch.setattr(main.auditor, "audit_document", fake_audit)
    files = {"file": ("../../etc/evil.png", b"x", "image/png")}
    response = client.post("/audit/document", files=files)
    assert response.status_code == 200
    assert "etc/evil" not in seen["path"]
    assert seen["path"].endswith(".png")


def test_parser_failure_fails_closed(client, monkeypatch):
    monkeypatch.setattr(main.auditor, "_call_vlm_api", lambda image, prompt: {"unexpected": "shape"})
    files = {"file": ("page2.png", b"x", "image/png")}
    body = client.post("/audit/document", files=files).json()
    assert body["is_safe"] is False
    assert body["risk_score"] == 1.0
