FROM python:3.10-slim

WORKDIR /app

# No system packages or model runtime yet: the VLM call is mocked (see visual_pii_auditor.py).
# A real backend would add an HTTP client or a local model runtime here.

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002"]
