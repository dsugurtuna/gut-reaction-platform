# Security Policy

## 🔒 Security is Our Priority

The Gut Reaction Platform handles sensitive clinical and genomic data. Security and compliance are fundamental to our design philosophy.

---

## 📋 Table of Contents

- [Supported Versions](#supported-versions)
- [Reporting a Vulnerability](#reporting-a-vulnerability)
- [Security Architecture](#security-architecture)
- [Compliance Framework](#compliance-framework)
- [Security Features](#security-features)
- [Security Best Practices](#security-best-practices)

---

## ✅ Supported Versions

| Version | Supported          | Notes |
|---------|--------------------|-------|
| 2.x.x   | :white_check_mark: | Current stable release |
| 1.x.x   | :warning:          | Security patches only |
| < 1.0   | :x:                | End of life |

---

## 🚨 Reporting a Vulnerability

### Do NOT open a public issue

For security vulnerabilities, please **do not** open a public GitHub issue.

### How to Report

1. **Email**: Send details to [security@example.com](mailto:security@example.com)
2. **Encrypt**: Use our PGP key (available at `/security/pgp-key.asc`)
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

| Stage | Timeframe |
|-------|-----------|
| Initial Response | 24 hours |
| Triage | 48 hours |
| Fix Development | 1-2 weeks |
| Disclosure | 90 days (coordinated) |

### Recognition

We maintain a [Security Hall of Fame](SECURITY_HALL_OF_FAME.md) for responsible disclosures.

---

## 🏛️ Security Architecture

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────────┐
│                    PERIMETER SECURITY                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  WAF / DDoS Protection                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  NETWORK SECURITY                        │    │
│  │  • VPC Isolation    • Security Groups    • NACLs        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  APPLICATION SECURITY                    │    │
│  │  • mTLS            • API Gateway         • Auth/AuthZ   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  DATA SECURITY                           │    │
│  │  • Encryption at Rest    • Encryption in Transit        │    │
│  │  • Key Management        • Data Masking                 │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Zero-Trust Model

- **Never trust, always verify**
- All service-to-service communication uses mTLS
- Short-lived tokens (JWT with 15-minute expiry)
- Principle of least privilege

---

## 📜 Compliance Framework

### NHS Five Safes Alignment

| Safe | Implementation |
|------|----------------|
| **Safe People** | Role-based access control, mandatory security training |
| **Safe Projects** | DAA approval workflow, ethical review integration |
| **Safe Settings** | TRE deployment, air-gapped genomic access |
| **Safe Data** | De-identification, k-anonymity checks |
| **Safe Outputs** | Visual AI audit, Statistical Disclosure Control |

### GDPR Compliance

- **Data Minimization**: VCF slicer extracts only requested variants
- **Purpose Limitation**: Per-project access controls
- **Storage Limitation**: Automated data retention policies
- **Right to Erasure**: Audit trail preserves compliance records
- **Data Portability**: Standard export formats (OMOP CDM)

### Technical Standards

| Standard | Status | Evidence |
|----------|--------|----------|
| ISO 27001 | ✅ | Deployed in AIMES certified TRE |
| SOC 2 Type II | 🔄 | In progress |
| OWASP Top 10 | ✅ | Annual penetration testing |
| CIS Benchmarks | ✅ | Container hardening |

---

## 🛡️ Security Features

### Authentication & Authorization

```yaml
# Example: Keycloak OIDC Configuration
auth:
  provider: keycloak
  issuer: https://auth.gut-reaction.nhs.uk/realms/research
  audience: gut-reaction-api
  roles:
    - researcher      # Read access to approved datasets
    - data_steward    # Approve data releases
    - admin           # Full platform access
```

### Encryption

| Data State | Method | Algorithm |
|------------|--------|-----------|
| At Rest | AWS KMS / HashiCorp Vault | AES-256-GCM |
| In Transit | TLS 1.3 | ECDHE + AES-256 |
| Backups | Client-side encryption | AES-256-CBC |

### Audit Logging

All actions are logged to an immutable audit trail:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "actor": "user:researcher@nhs.uk",
  "action": "DATA_ACCESS",
  "resource": "cohort:IBD-2024-001",
  "outcome": "SUCCESS",
  "metadata": {
    "ip": "10.0.1.100",
    "user_agent": "gut-reaction-cli/1.0",
    "session_id": "abc123"
  }
}
```

### Network Security

```yaml
# Kubernetes NetworkPolicy Example
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: phenotype-nlp-policy
spec:
  podSelector:
    matchLabels:
      app: phenotype-nlp
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api-gateway
      ports:
        - port: 8001
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - port: 5432
```

---

## 🔐 Security Best Practices

### For Developers

1. **Never commit secrets** - Use `.env` files (gitignored) or secret managers
2. **Validate all inputs** - Use Pydantic (Python) / checkmate (R)
3. **Use parameterized queries** - Prevent SQL injection
4. **Keep dependencies updated** - Run `dependabot` alerts
5. **Review code** - All PRs require security-aware review

### For Operators

1. **Rotate credentials** - 90-day maximum for service accounts
2. **Monitor alerts** - Configure Prometheus/Grafana dashboards
3. **Patch promptly** - Critical vulnerabilities within 24 hours
4. **Test backups** - Monthly restoration drills
5. **Review access** - Quarterly access audits

### For Researchers

1. **Use VPN** - Access TRE only via approved network
2. **Report anomalies** - Contact security team immediately
3. **No data export** - All outputs go through Airlock
4. **Secure workstation** - Follow endpoint security policy
5. **Training** - Complete annual security awareness course

---

## 🔍 Security Scanning

### Automated Scans

| Tool | Purpose | Frequency |
|------|---------|-----------|
| **Trivy** | Container vulnerabilities | Every build |
| **Snyk** | Dependency vulnerabilities | Daily |
| **SonarQube** | Code quality & security | Every PR |
| **OWASP ZAP** | DAST scanning | Weekly |
| **Checkov** | IaC security | Every PR |

### CI/CD Integration

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'
          
      - name: Run Snyk
        uses: snyk/actions/python@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

---

## 📞 Security Contacts

| Role | Contact |
|------|---------|
| Security Lead | security@example.com |
| On-Call (24/7) | +44 XXX XXX XXXX |
| Bug Bounty | hackerone.com/gut-reaction |

---

## 📚 Additional Resources

- [OWASP Top 10](https://owasp.org/Top10/)
- [NHS Data Security Standards](https://www.dsptoolkit.nhs.uk/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [NCSC Cyber Essentials](https://www.ncsc.gov.uk/cyberessentials)

---

*Last Updated: November 2024*
