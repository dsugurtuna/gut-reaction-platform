# Same interpreter as the CI unit tests (.github/workflows/ci.yml).
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Small general-English spaCy model. The extractor only needs its tokenizer; the SciSpacy
# model it asks for first (en_core_sci_md) is not installed, so it falls back to this one.
RUN pip install --no-cache-dir "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.5.0/en_core_web_sm-3.5.0-py3-none-any.whl"

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
