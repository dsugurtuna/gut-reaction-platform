# Contributing

Thanks for taking a look. This is a personal project, so the process is light.

## Before you start

- Open an issue first for anything bigger than a small fix, so we can agree the approach.
- Use synthetic or openly licensed data only. Never commit, paste or attach real patient or
  participant data, including in issues and screenshots.

## Set up and check your change

```bash
make test   # Python and R unit tests
make lint   # ruff, same pinned version as CI
make ui     # only if you touched ui/
```

CI also builds the images and runs integration checks against the two Python services. See
[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the full list of jobs.

## Conventions

- Python: type hints, ruff-clean (`pyproject.toml` holds the settings), tests in each service's
  `tests/` folder that run offline with no API keys.
- R: keep pure rules (no file I/O) in the `*_rules.R` files so tests can source the real code.
- Commits: conventional prefixes (`fix:`, `feat:`, `docs:`, `test:`, `ci:`, `build:`, `chore:`),
  one logical change per commit.
- Docs: say what the code does today. If something is mocked, partial or untested, write that down.

## Licence

By contributing you agree that your contribution is licensed under the Apache License 2.0, the
licence of this repository.
