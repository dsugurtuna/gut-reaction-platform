# Contributing to Gut Reaction Platform

First off, thank you for considering contributing to the Gut Reaction Platform! 🎉

This document provides guidelines and information for contributing. Please read through before opening issues or pull requests.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)
- [Documentation](#documentation)

---

## 📜 Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to [maintainers@example.com](mailto:maintainers@example.com).

### Our Standards

- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

---

## 🚀 Getting Started

### Types of Contributions

We welcome many types of contributions:

| Type | Description |
|------|-------------|
| 🐛 **Bug Reports** | Report issues you encounter |
| ✨ **Feature Requests** | Suggest new features or improvements |
| 📝 **Documentation** | Improve docs, examples, or comments |
| 🔧 **Code** | Fix bugs or implement new features |
| 🧪 **Tests** | Add or improve test coverage |
| 🌐 **Translations** | Help translate documentation |

### First Time Contributors

Look for issues labeled:
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `documentation` - Documentation improvements

---

## 💻 Development Setup

### Prerequisites

```bash
# Required
- Docker 20.10+
- Docker Compose 2.0+
- Python 3.9+
- R 4.2+
- Node.js 18+ (for UI development)
- Make

# Optional
- kubectl (for K8s deployment)
- terraform (for cloud deployment)
```

### Local Setup

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/gut-reaction.git
cd gut-reaction

# 3. Add upstream remote
git remote add upstream https://github.com/dsugurtuna/gut-reaction.git

# 4. Create a branch
git checkout -b feature/your-feature-name

# 5. Copy environment file
cp .env.example .env

# 6. Start development environment
make dev

# 7. Run tests
make test
```

### IDE Setup

#### VS Code (Recommended)

Install recommended extensions:
```json
{
  "recommendations": [
    "ms-python.python",
    "REditorSupport.r",
    "ms-azuretools.vscode-docker",
    "hashicorp.terraform",
    "esbenp.prettier-vscode"
  ]
}
```

---

## 📁 Project Structure

```
gut-reaction/
├── .github/                    # GitHub configuration
│   ├── workflows/              # CI/CD pipelines
│   └── ISSUE_TEMPLATE/         # Issue templates
├── docs/                       # Documentation
├── infrastructure/             # IaC configurations
│   ├── k8s/                    # Kubernetes manifests
│   └── terraform/              # Terraform modules
├── services/                   # Microservices
│   ├── clinical-ingestion/     # R/Plumber service
│   ├── genomic-bridge/         # R/Bioconductor service
│   ├── governance-auditor/     # Python/VLM service
│   └── phenotype-nlp/          # Python/FastAPI service
├── ui/                         # React frontend
├── docker-compose.yml          # Local orchestration
├── Makefile                    # Build automation
└── README.md                   # Project overview
```

---

## 📐 Coding Standards

### Python

We follow [PEP 8](https://pep8.org/) with the following tools:

```bash
# Formatter
black --line-length 100

# Linter
ruff check

# Type checking
mypy --strict
```

**Example:**
```python
from typing import List, Optional

from pydantic import BaseModel


class ClinicalNote(BaseModel):
    """A clinical note document for NLP processing."""

    patient_id: str
    text_content: str
    metadata: Optional[dict] = None

    def validate_content(self) -> bool:
        """Validate note content is not empty."""
        return bool(self.text_content.strip())
```

### R

We follow the [Tidyverse Style Guide](https://style.tidyverse.org/):

```r
# Use snake_case for functions and variables
process_trust_data <- function(input_file, trust_id) {
  # Validate inputs with checkmate
  checkmate::assert_file_exists(input_file)
  checkmate::assert_choice(trust_id, c("CAMBS", "LEEDS"))
  
  # Use tidyverse verbs
  clean_data <- read_csv(input_file) |>
    filter(!is.na(patient_id)) |>
    mutate(trust = trust_id)
  
  return(clean_data)
}
```

### Bash

Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html):

```bash
#!/bin/bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
    local input_file="$1"
    
    if [[ ! -f "$input_file" ]]; then
        echo "Error: File not found: $input_file" >&2
        exit 1
    fi
    
    process_file "$input_file"
}

main "$@"
```

---

## 📝 Commit Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Code style (formatting, etc) |
| `refactor` | Code refactoring |
| `perf` | Performance improvement |
| `test` | Adding tests |
| `chore` | Maintenance tasks |
| `ci` | CI/CD changes |

### Examples

```bash
# Feature
feat(nlp): add IBD severity extraction pipeline

# Bug fix
fix(bridge): correct sample ID mapping for Sanger format

# Documentation
docs(readme): add deployment instructions for AWS

# Breaking change
feat(api)!: change response format for /extract/vte endpoint

BREAKING CHANGE: The response now returns an array of evidence
instead of a comma-separated string.
```

---

## 🔄 Pull Request Process

### Before Submitting

- [ ] Tests pass locally (`make test`)
- [ ] Code is formatted (`make lint`)
- [ ] Documentation is updated
- [ ] Commit messages follow guidelines
- [ ] Branch is up-to-date with `main`

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking)
- [ ] New feature (non-breaking)
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
```

### Review Process

1. **Automated Checks**: CI must pass
2. **Code Review**: At least 1 approval required
3. **Testing**: Reviewer may request additional tests
4. **Documentation**: Ensure docs reflect changes
5. **Merge**: Squash and merge preferred

---

## 🧪 Testing

### Python Services

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html

# Run specific test file
pytest tests/test_vte_extractor.py
```

### R Services

```r
# Using testthat
devtools::test()

# Run specific test
testthat::test_file("tests/test_harmonizer.R")
```

### Integration Tests

```bash
# Start services and run integration tests
make test-integration
```

### Test Structure

```
services/phenotype-nlp/
├── src/
│   └── vte_extractor.py
└── tests/
    ├── __init__.py
    ├── conftest.py          # Fixtures
    ├── test_vte_extractor.py
    └── test_integration.py
```

---

## 📖 Documentation

### Where to Document

| Content | Location |
|---------|----------|
| API Reference | `docs/API.md` |
| Architecture | `docs/ARCHITECTURE.md` |
| Deployment | `docs/DEPLOYMENT.md` |
| Code Comments | Inline docstrings |
| README | `README.md` |

### Docstring Format

**Python:**
```python
def extract_vte(text: str) -> dict:
    """Extract VTE signals from clinical text.

    Args:
        text: The clinical note text to analyze.

    Returns:
        A dictionary containing:
            - has_vte: Boolean indicating VTE presence
            - confidence: Float between 0 and 1
            - evidence: List of extracted terms

    Raises:
        ValueError: If text is empty.

    Example:
        >>> extract_vte("Patient has pulmonary embolism")
        {"has_vte": True, "confidence": 0.95, "evidence": ["pulmonary embolism"]}
    """
```

**R:**
```r
#' Process Trust Prescribing Data
#'
#' ETL pipeline for standardizing NHS Trust medication data.
#'
#' @param file_path Path to the raw Excel file.
#' @param trust_id Trust identifier (CAMBS, LEEDS, etc.).
#'
#' @return A tibble with harmonized columns.
#'
#' @examples
#' process_trust_prescribing("data/CAMBS.xlsx", "CAMBS")
#'
#' @export
```

---

## ❓ Questions?

- **GitHub Issues**: For bugs and features
- **Discussions**: For questions and ideas
- **Email**: maintainers@example.com

---

Thank you for contributing! 🙏
