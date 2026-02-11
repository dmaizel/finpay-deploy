# finpay-deploy

Deployment charts and manifests for the **FinPay Enterprise Lab** — a scenario-driven Octopus Deploy exercise simulating a real mid-size fintech company.

## Quick Start

1. **Fork this repo** to your own GitHub account
2. Clone your fork locally
3. Follow the [Enterprise Lab Guide](https://github.com/YOUR_ORG/octopus-k8s-usecase/blob/main/enterprise-lab.md) *(update link)*

## Structure

```
├── charts/
│   ├── payments-api/          # Helm chart — core payments service
│   ├── fraud-detector/        # Helm chart — ML fraud detection
│   └── merchant-portal/       # Helm chart — merchant-facing portal
├── manifests/
│   └── kyc-service/           # Raw K8s YAML (Octopus variable substitution)
├── argocd-manifests/
│   └── payments-api/          # ArgoCD-managed manifests (per environment)
│       ├── development/
│       ├── staging/
│       └── production/
└── setup/
    └── bootstrap.sh           # Creates Kind clusters + namespaces
```

## Services

| Service | Chart Type | Octopus Space | Notes |
|---------|-----------|---------------|-------|
| `payments-api` | Helm | Payments | Core service, approval gates for prod |
| `fraud-detector` | Helm | Payments | ML service, restart runbook |
| `merchant-portal` | Helm | Merchants | Tenanted (per-merchant) deployments |
| `kyc-service` | Raw YAML | Merchants | PII handler, stricter compliance |

All services use `nginx:1.25-alpine` as the container image. The charts are structured like real production services (env-specific values, HPA, PDB, health checks) but the actual workload is nginx.

## What You'll Need

- Docker Desktop
- `kind`, `kubectl`, `helm`
- An Octopus Cloud trial (Enterprise): https://octopus.com/start
- A GitHub account
