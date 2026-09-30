# Deployment guide

What you can run, what CI checks, and what has never been tried. Nothing in this repository has
been deployed to a shared or production environment.

## Local, without Docker

Needs Python 3.11, R (with `testthat`, `dplyr`, `tibble`, `stringr`, `checkmate`) and Node.js 22.

```bash
make test          # pytest for both Python services, testthat for both R services
make lint          # ruff 0.16.9
make ui            # npm ci + tsc + vite build
make k8s-validate  # needs kubectl and kubeconform on PATH
```

To run one Python service directly:

```bash
cd services/phenotype-nlp
../../.venv-nlp/bin/uvicorn main:app --port 8001   # the venv is created by `make test-nlp`
```

## Docker Compose

| Command | Starts | Tested by CI |
|---|---|---|
| `make up` (`docker-compose.ci.yml`) | phenotype-nlp, governance-auditor, Postgres | Yes: the integration job builds these images and checks responses |
| `make up-all` (`docker-compose.yml`) | the above plus the R services, nginx gateway, dashboard and Redis | No |

`docker-compose.yml` bind-mounts `./data/clinical` and `/mnt/hpc/data` (read-only) into the R
services. On Docker Desktop, `/mnt/hpc/data` has to be shared with Docker or removed from the file.

Both compose files set a Postgres password in plain text. Nothing uses the database yet.

## CI/CD (`.github/workflows/ci.yml`)

The workflow runs on pushes to `main` or `develop`, on pull requests into them, and by hand.

| Job | Runs on | What it checks |
|---|---|---|
| Lint & Format Check | every push and PR | `ruff check` and `ruff format --check` (ruff 0.16.9) |
| Security Scan | every push and PR | Trivy filesystem scan in report-only mode (`exit-code: 0`); Snyk with `continue-on-error`, which also needs a `SNYK_TOKEN` secret to authenticate. Neither can fail the build. |
| Python Tests | every push and PR | pytest with coverage for both Python services |
| R Tests | every push and PR | testthat for both R services |
| Dashboard Build | every push and PR | `npm ci`, `tsc`, `vite build` |
| Validate K8s Manifests | every push and PR | `kubectl kustomize` + `kubeconform` against Kubernetes 1.28 schemas |
| Integration Tests | every push and PR, after lint and Python tests | builds `docker-compose.ci.yml`, calls both services and checks the response bodies |
| Build & Push Images | pushes and manual runs on `main`, after integration and R tests | builds all four service images and pushes them to `ghcr.io/dsugurtuna/gut-reaction-platform/<service>` |
| Deploy to Production | manual runs on `main` only | see below |

The deploy job runs only when someone starts the workflow by hand (Actions, "CI/CD Pipeline",
"Run workflow") on `main`. It needs a base64-encoded kubeconfig in a `KUBECONFIG` repository
secret and fails with a clear message without one. There is no cluster behind this repository, so
in practice it has never run.

## Kubernetes (`infrastructure/k8s/base`)

A single kustomize base for the two Python services: Namespace, two Deployments, two Services, two
HorizontalPodAutoscalers, an Ingress, three NetworkPolicies, a ConfigMap and a Secret. CI checks
that it renders and matches the Kubernetes 1.28 API schemas. That is a structural check only.

Known gaps before it could run:

- It refers to objects it does not define: ServiceAccount `gut-reaction-sa`, PersistentVolumeClaims
  `nlp-model-pvc` and `audit-logs-pvc`, Secret `vlm-credentials`, Services `clinical-ingestion` and
  `genomic-bridge` (Ingress backends), and a Postgres service.
- `default-deny-all` blocks all egress and no policy allows any back, so pods cannot resolve DNS.
- The Secret generator holds a placeholder password (`CHANGE_ME_IN_PRODUCTION`) in git. Use an
  external secret store instead.
- Pods carry `prometheus.io/scrape` annotations, but neither service exposes `/metrics`.
- Images use the `latest` tag with `imagePullPolicy: Always`. Pin a digest or the `sha-` tag that
  CI pushes.
- The Ingress host is `api.gut-reaction.example.org`, a placeholder.
- There is no overlay per environment (`overlays/` does not exist).

## Terraform (`infrastructure/terraform/aws`)

Describes a VPC with flow logs, an EKS cluster (version 1.28, a general node group and a GPU node
group), RDS PostgreSQL 15 with storage encrypted by a KMS key, a single-node ElastiCache Redis,
and security groups that allow the database and cache only from the EKS nodes.

It has never been planned or applied, and CI does not run `terraform validate`. `terraform fmt
-check` currently reports whitespace differences in `main.tf`. Before using it:

- create the S3 state bucket and DynamoDB lock table named in the `backend "s3"` block;
- check the pinned versions (EKS 1.28, PostgreSQL 15.4, module majors) against what AWS and the
  modules support today;
- remove or justify `log_statement = all` on RDS, which writes every statement, including values,
  to the logs;
- add encryption at rest and in transit for Redis (the plain `aws_elasticache_cluster` resource
  sets neither);
- decide whether the GPU node group is needed: nothing in this repository uses a GPU;
- remove the `kubernetes` and `helm` providers or use them; nothing does yet.
