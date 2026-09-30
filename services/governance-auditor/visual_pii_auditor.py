from __future__ import annotations

import logging
import os
from dataclasses import dataclass
from enum import Enum


# Model identifiers the auditor is designed for. Neither is called: see VisualPIIAuditor.MOCKED.
class VLMProvider(Enum):
    OPENAI_GPT4V = "gpt-4-vision-preview"
    LLAVA_NEXT = "llava-v1.6-34b"


@dataclass
class AuditResult:
    is_safe: bool
    risk_score: float
    detected_pii: list[str]
    reasoning: str


class VisualPIIAuditor:
    """
    Visual PII auditor: the design for a final visual check of redacted documents
    by a vision-language model (VLM) before they leave a secure environment.

    The intended checks are ones that text-based rules miss:
    - Names written in margins.
    - Failed redaction boxes (transparent overlays).
    - PII in embedded screenshots or charts.

    Reference implementation: the model call is mocked. ``_call_vlm_api`` returns
    the same canned response for every input, and ``_encode_image`` does not read
    the file. The prompt, the response parsing and the fail-closed behaviour are real.
    """

    # There is no real VLM client yet, with or without an API key.
    MOCKED = True

    def __init__(
        self,
        model: VLMProvider = VLMProvider.OPENAI_GPT4V,
        api_key: str | None = None,
    ):
        self.model = model
        self.api_key = api_key or os.getenv("VLM_API_KEY")
        self.logger = logging.getLogger("VisualGovernance")
        self.logger.setLevel(logging.INFO)

        self.logger.warning(
            "VLM calls are mocked: every document gets the same canned response and the file is not read."
        )

    def audit_document(self, image_path: str) -> AuditResult:
        """
        Audits a single document page (image) for visible PII.
        """
        self.logger.info(f"Starting visual audit for: {image_path}")

        # 1. Pre-processing (Resize, Normalize)
        # In a real scenario, we would use PIL/OpenCV here to optimize the image for the VLM token limit.
        encoded_image = self._encode_image(image_path)

        # 2. Construct the Visual Prompt
        prompt = self._get_audit_prompt()

        # 3. Call the VLM (Mocked for Shadow Repo)
        response = self._call_vlm_api(encoded_image, prompt)

        # 4. Parse Response
        return self._parse_vlm_response(response)

    def _encode_image(self, image_path: str) -> str:
        # Mock encoding
        return "base64_encoded_image_string"

    def _get_audit_prompt(self) -> str:
        return """
        You are a strict Privacy Compliance Officer. 
        Analyze this document image for any visible Personally Identifiable Information (PII).
        
        Look specifically for:
        1. Patient Names (e.g., "John Doe")
        2. Dates of Birth (DOB)
        3. NHS Numbers or Hospital IDs
        4. Unredacted faces in medical photos
        5. Text visible *under* a black redaction box (failed redaction)
        
        Return a JSON object with:
        - "is_safe": boolean
        - "risk_score": 0.0 to 1.0
        - "detected_pii": list of strings
        - "reasoning": brief explanation
        """

    def _call_vlm_api(self, image_data: str, prompt: str) -> dict:
        """
        Simulates the API call to GPT-4V or LLaVA.
        """
        self.logger.info(f"Sending request to {self.model.value}...")

        # --- MOCK RESPONSE LOGIC ---
        # In a real deployment, this would be:
        # client.chat.completions.create(model="gpt-4-vision-preview", messages=[...])

        return {
            "choices": [
                {
                    "message": {
                        "content": """
                    {
                        "is_safe": false,
                        "risk_score": 0.95,
                        "detected_pii": ["Patient Name: Sarah Jones", "DOB: 12/05/1980"],
                        "reasoning": "Found unredacted patient name in the top-left header and DOB in the footer. Redaction box on the diagnosis section is transparent."
                    }
                    """
                    }
                }
            ]
        }

    def _parse_vlm_response(self, api_response: dict) -> AuditResult:
        import json

        try:
            content = api_response["choices"][0]["message"]["content"]
            data = json.loads(content)
            return AuditResult(
                is_safe=data["is_safe"],
                risk_score=data["risk_score"],
                detected_pii=data["detected_pii"],
                reasoning=data["reasoning"],
            )
        except (KeyError, IndexError, TypeError, ValueError) as e:
            # Fail closed: a response we cannot read is treated as unsafe.
            self.logger.error(f"Failed to parse VLM response: {e}")
            return AuditResult(False, 1.0, ["Error"], "Parser Failure")


if __name__ == "__main__":
    # Setup logging
    logging.basicConfig(format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")

    auditor = VisualPIIAuditor()

    # Simulate a check on a "Redacted" PDF page
    result = auditor.audit_document("outputs/redacted_reports/patient_001_page1.png")

    print("\n--- AUDIT REPORT ---")
    print(f"Safe to Release: {result.is_safe}")
    print(f"Risk Score: {result.risk_score}")
    print(f"Findings: {result.detected_pii}")
    print(f"Analysis: {result.reasoning}")

    if not result.is_safe:
        print("\n[BLOCKING] File has been quarantined. Alerting Data Governance Team.")
