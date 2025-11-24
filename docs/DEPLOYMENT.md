# Deployment Guide

## 🚀 Gut Reaction Platform Deployment

This guide covers deployment options from local development to production Kubernetes clusters.

---

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Docker Compose](#docker-compose)
- [Kubernetes](#kubernetes)
- [Cloud Deployment](#cloud-deployment)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 20.10+ | Container runtime |
| Docker Compose | 2.0+ | Local orchestration |
| kubectl | 1.28+ | Kubernetes CLI |
| Helm | 3.12+ | Kubernetes package manager |
| Terraform | 1.5+ | Infrastructure as Code |

### Verify Installation

```bash
docker --version
docker-compose --version
kubectl version --client
helm version
terraform version
```

---

## Local Development

### Quick Start

```bash
# Clone repository
git clone https://github.com/dsugurtuna/gut-reaction.git
cd gut-reaction

# Copy environment file
cp .env.example .env

# Start all services
make dev

# View logs
make logs
```

### Service URLs

| Service | URL |
|---------|-----|
| Dashboard | http://localhost:3000 |
| NLP API | http://localhost:8001/docs |
| Auditor API | http://localhost:8003/docs |
| PostgreSQL | localhost:5432 |

### Hot Reload

Development mode includes hot-reload for Python services:

```yaml
# docker-compose.dev.yml
services:
  phenotype-nlp:
    volumes:
      - ./services/phenotype-nlp/src:/app/src:ro
    environment:
      - RELOAD=true
```

---

## Docker Compose

### Production Build

```bash
# Build all images
docker-compose build

# Start in detached mode
docker-compose up -d

# Check status
docker-compose ps
```

### Scaling Services

```bash
# Scale NLP service to 3 replicas
docker-compose up -d --scale phenotype-nlp=3
```

### Resource Limits

```yaml
# docker-compose.yml
services:
  phenotype-nlp:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

---

## Kubernetes

### Cluster Requirements

- Kubernetes 1.28+
- Minimum 3 nodes (2 CPU, 8GB RAM each)
- StorageClass with dynamic provisioning
- Ingress controller (NGINX recommended)

### Directory Structure

```
infrastructure/k8s/
├── base/                    # Base manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── phenotype-nlp/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── governance-auditor/
│   ├── clinical-ingestion/
│   └── genomic-bridge/
└── overlays/
    ├── development/
    │   └── kustomization.yaml
    ├── staging/
    └── production/
        └── kustomization.yaml
```

### Deploy with Kustomize

```bash
# Development
kubectl apply -k infrastructure/k8s/overlays/development/

# Production
kubectl apply -k infrastructure/k8s/overlays/production/
```

### Example Deployment Manifest

```yaml
# infrastructure/k8s/base/phenotype-nlp/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: phenotype-nlp
  labels:
    app: phenotype-nlp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: phenotype-nlp
  template:
    metadata:
      labels:
        app: phenotype-nlp
    spec:
      containers:
        - name: phenotype-nlp
          image: ghcr.io/dsugurtuna/gut-reaction/phenotype-nlp:latest
          ports:
            - containerPort: 8001
          env:
            - name: MODEL_PATH
              value: /models/en_core_sci_lg
            - name: DB_HOST
              valueFrom:
                secretKeyRef:
                  name: database-credentials
                  key: host
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2000m"
              memory: "4Gi"
          livenessProbe:
            httpGet:
              path: /health
              port: 8001
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 8001
            initialDelaySeconds: 5
            periodSeconds: 5
```

### Horizontal Pod Autoscaler

```yaml
# infrastructure/k8s/base/phenotype-nlp/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: phenotype-nlp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: phenotype-nlp
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### Network Policies

```yaml
# infrastructure/k8s/base/network-policy.yaml
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

## Cloud Deployment

### AWS (Terraform)

```hcl
# infrastructure/terraform/aws/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "gut-reaction-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = false
  
  tags = {
    Environment = var.environment
    Project     = "gut-reaction"
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = "gut-reaction-${var.environment}"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  eks_managed_node_groups = {
    general = {
      min_size     = 2
      max_size     = 10
      desired_size = 3
      
      instance_types = ["m5.large"]
      
      labels = {
        Environment = var.environment
      }
    }
    
    gpu = {
      min_size     = 0
      max_size     = 5
      desired_size = 1
      
      instance_types = ["g4dn.xlarge"]
      
      labels = {
        workload = "gpu"
      }
      
      taints = [{
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"
  
  identifier = "gut-reaction-${var.environment}"
  
  engine               = "postgres"
  engine_version       = "15.4"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = "db.t3.medium"
  
  allocated_storage     = 100
  max_allocated_storage = 500
  
  db_name  = "gut_reaction_db"
  username = "admin"
  port     = 5432
  
  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group_rds.security_group_id]
  
  backup_retention_period = 30
  deletion_protection     = true
  
  tags = {
    Environment = var.environment
  }
}
```

### Deploy to AWS

```bash
cd infrastructure/terraform/aws

# Initialize
terraform init

# Plan
terraform plan -var-file="production.tfvars"

# Apply
terraform apply -var-file="production.tfvars"
```

---

## Monitoring

### Prometheus & Grafana

```yaml
# infrastructure/k8s/monitoring/prometheus.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: phenotype-nlp
spec:
  selector:
    matchLabels:
      app: phenotype-nlp
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
```

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `nlp_requests_total` | Total API requests | N/A |
| `nlp_request_duration_seconds` | Request latency | P95 > 500ms |
| `nlp_batch_queue_size` | Pending batch jobs | > 100 |
| `audit_documents_scanned` | Documents audited | N/A |
| `audit_pii_detected` | PII findings | Any |

### Grafana Dashboard

Import dashboard from `infrastructure/monitoring/grafana/dashboards/gut-reaction.json`

---

## Troubleshooting

### Common Issues

#### Services Not Starting

```bash
# Check logs
docker-compose logs phenotype-nlp

# Check resource usage
docker stats

# Verify network
docker network ls
```

#### Database Connection Issues

```bash
# Test connection
docker-compose exec postgres psql -U admin -d gut_reaction_db -c "SELECT 1"

# Check secrets
kubectl get secret database-credentials -o yaml
```

#### Out of Memory

```bash
# Increase Docker memory
# Docker Desktop > Settings > Resources > Memory

# Or reduce batch size
export NLP_BATCH_SIZE=25
```

### Health Checks

```bash
# All services
curl http://localhost:8001/health
curl http://localhost:8003/health

# Kubernetes
kubectl get pods -l app=phenotype-nlp
kubectl describe pod <pod-name>
```

### Logs

```bash
# Docker Compose
docker-compose logs -f phenotype-nlp

# Kubernetes
kubectl logs -f deployment/phenotype-nlp
kubectl logs -f deployment/phenotype-nlp --previous
```

---

## Backup & Recovery

### Database Backup

```bash
# Manual backup
make db-backup

# Automated (cron)
0 2 * * * /opt/gut-reaction/scripts/backup.sh
```

### Restore

```bash
# From backup file
make db-restore FILE=backup_20240115.sql
```

---

## Security Checklist

Before going to production:

- [ ] Change all default passwords
- [ ] Enable TLS/SSL certificates
- [ ] Configure network policies
- [ ] Enable audit logging
- [ ] Set up monitoring alerts
- [ ] Configure backup schedule
- [ ] Review RBAC permissions
- [ ] Run security scan
