# API reference

Every endpoint that exists today, with responses captured from the running code. There is no
authentication, no versioned path prefix and no rate limiting. The two FastAPI services also serve
interactive docs at `/docs` and the schema at `/openapi.json`.

Ports below are the ones `docker-compose.ci.yml` publishes (`make up`). Through the gateway in
`docker-compose.yml` (`make up-all`), use `http://localhost:8000` with the paths described in
[ARCHITECTURE.md](ARCHITECTURE.md#supporting-pieces).

## phenotype-nlp (port 8001)

### `GET /health`

```json
{"status":"healthy","spacy_pipeline":"en_core_web_sm"}
```

`spacy_pipeline` is the pipeline that actually loaded (see
[ARCHITECTURE.md](ARCHITECTURE.md#phenotype-nlp)).

### `POST /extract/vte`

Request:

```json
{
  "patient_id": "P001",
  "encounter_id": "E001",
  "text_content": "CT shows acute pulmonary embolism. No DVT.",
  "metadata": {}
}
```

`metadata` is optional and ignored. Missing required fields return `422`.

Responses:

```json
{"patient_id":"P001","status":"POSITIVE_VTE","has_vte":true,"confidence":0.95,"evidence":["pulmonary embolism"]}
{"patient_id":"P002","status":"NEGATIVE_VTE","has_vte":false,"confidence":0.0,"evidence":[]}
{"patient_id":"P003","status":"NO_MENTION","has_vte":false,"confidence":0.0,"evidence":[]}
```

(for "CT shows acute pulmonary embolism. No DVT.", "Pulmonary arteries are clear. No evidence of
pulmonary embolism." and "Mild headache.")

- `status` is one of `POSITIVE_VTE`, `NEGATIVE_VTE` (every mention negated) or `NO_MENTION`.
- `evidence` lists the non-negated matched terms, as written, each once.
- `confidence` is a fixed placeholder: 0.95 for a positive result and 0.0 otherwise. It is not a
  calibrated probability.

### `POST /batch/process`

Request: a JSON array of the same note objects. Response:

```json
{"message":"Batch received","count":1}
```

The notes are processed after the response is sent. The service logs a count per status; results
are not stored or returned. There is no status endpoint for a batch.

## governance-auditor (port 8002)

### `GET /health`

```json
{"status":"healthy","vlm_model":"gpt-4-vision-preview","vlm_mocked":true}
```

### `POST /audit/document`

Multipart upload with one field, `file`.

```bash
curl -s -X POST http://localhost:8002/audit/document -F "file=@page1.png"
```

```json
{"filename":"page1.png","is_safe":false,"risk_score":0.95,"detected_issues":["Patient Name: Sarah Jones","DOB: 12/05/1980"],"reasoning":"Found unredacted patient name in the top-left header and DOB in the footer. Redaction box on the diagnosis section is transparent.","mocked":true}
```

While `mocked` is `true`, this is the same canned answer for every file: the name and date are
invented, and the file is not read. If a model reply cannot be parsed, the result is
`is_safe: false` with `risk_score: 1.0`.

## clinical-ingestion (R, port 8000 inside the container)

plumber wraps scalar values in arrays, so responses look like `{"status":["online"]}`.

### `GET /health`

```json
{"status":["online"],"backend":["R 4.2.0"]}
```

### `POST /harmonize?input_file=<path>&trust_id=<code>`

`input_file` is a path on the server to an Excel file with columns `Patient ID`, `Drug`,
`Rx Date`, `Dose`, `Frequency` (any case; spaces become underscores). `trust_id` must be one of
`CAMBS`, `LEEDS`, `MANCH`, `LPOOL`.

```json
{"status":["success"],"rows_processed":[2],"message":["Drug names standardised and rows passing QC kept (flat table, not OMOP CDM)"]}
```

Errors come back with HTTP 200 and `"status":["error"]`, for example for an unknown `trust_id`.
The harmonised rows are not written anywhere by this endpoint.

## genomic-bridge (R, port 8000 inside the container)

### `GET /health`

```json
{"status":["online"]}
```

### `GET /status/<patient_id>`

A mock. It always reports a link and invents a sample ID:

```json
{"mocked":[true],"patient_id":["P001"],"has_linkage":[true],"sanger_id":["SANGER_P001"]}
```

### `POST /link-cohort?cohort_file=<path>`

Runs `link_clinical_to_genomic()` with the given cohort CSV and fixed paths for the bridge table
(`/data/secure/mpi_bridge.csv`) and manifest (`/hpc/manifests/genomic_inventory.csv`). Neither
fixed file exists in the images. The response has `linked_count`, the number of samples that pass
the linkage and QC rules, and an `export_path` that nothing writes to yet.
