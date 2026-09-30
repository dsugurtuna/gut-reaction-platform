# Security policy

This is a personal reference implementation. It is not deployed anywhere and has never handled
real patient data. Fixes go to `main`; there are no maintained release branches.

## Reporting a vulnerability

Please do not put details of a vulnerability in a public issue.

- If the repository's **Security** tab offers **Report a vulnerability**, use it.
- Otherwise, open an issue that only asks for a private contact, and the details can follow there.

Never include real patient or participant data in a report, an issue or a pull request.

## Known security limitations

These are gaps in the current code, not undiscovered vulnerabilities:

- No endpoint authenticates or authorises callers, and there is no TLS between containers.
- `clinical-ingestion` `POST /harmonize` and `genomic-bridge` `POST /link-cohort` take file paths
  from the caller and read them on the server. Do not expose them to untrusted clients.
- The compose files and the Kubernetes Secret generator contain placeholder database passwords.
- The Kubernetes NetworkPolicies are untested on a real cluster (see
  [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)).
- The Terraform enables `log_statement = all` on RDS, which would put query values in the logs.
- The CI security scan (Trivy, Snyk) reports findings but never fails the build.

## What the design tries to do

- Keep steps apart: the text service never sees genomic paths, and the linkage service never sees
  free text.
- Keep identifiers out of logs: phenotype-nlp logs note length, not patient IDs or text.
- Fail closed: the document auditor treats any reply it cannot parse as unsafe.
- Say when something is mocked: the auditor reports `mocked: true` in every response.
