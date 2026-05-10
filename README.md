# K8s Platform

A self-hosted Kubernetes platform running on AWS EC2 using k3s. Infrastructure is provisioned with Terraform and all workloads are deployed via GitOps using ArgoCD — every push to this repository automatically deploys to the cluster. Automatic HTTPS is handled by cert-manager and Let's Encrypt for all subdomains.

## Architecture

```
GitHub (k8s-platform repo)
    ↓ ArgoCD watches every 3 minutes
k3s Cluster (EC2 t3.medium)
    ├── argocd (namespace)      — GitOps engine
    ├── cert-manager (namespace) — automatic TLS certificates
    ├── monitoring (namespace)
    │   ├── Grafana             — dashboards (CloudWatch + Prometheus)
    │   └── Prometheus stack    — Kubernetes metrics
    └── kube-system (namespace)
        └── Traefik             — ingress controller
```

## GitOps Flow

```
Edit manifest → git push → ArgoCD detects change → deploys to cluster
```

No manual `kubectl apply` needed. The cluster always reflects what is in this repo.

## Stack

| Tool | Purpose |
|------|---------|
| k3s | Lightweight Kubernetes on EC2 |
| Terraform | Provisions EC2, VPC, IAM, Elastic IP |
| ArgoCD | GitOps —> auto-deploys from GitHub |
| Traefik | Ingress controller —> routes traffic to services |
| cert-manager | Automatic TLS certificates via Let's Encrypt |
| Grafana | Monitoring dashboards |
| Prometheus | Kubernetes metrics collection |
| AWS CloudWatch | EC2 and billing metrics |

## Infrastructure

- EC2 t3.medium (2 vCPU, 4GB RAM) running Ubuntu 22.04
- Elastic IP for stable DNS
- IAM role attached for CloudWatch access
- Remote Terraform state in S3
- Security group allowing ports 22, 80, 443, 6443

## Project Structure

```
k8s-platform/
├── terraform/
│   ├── main.tf          # EC2, VPC, security groups, Elastic IP
│   ├── providers.tf     # AWS provider + S3 backend
│   └── variables.tf     # Input variables
└── manifests/
    ├── cert-manager.yaml      # cert-manager via Helm (ArgoCD app)
    ├── cluster-issuer.yaml    # Let's Encrypt ClusterIssuer
    ├── prometheus.yaml        # kube-prometheus-stack (ArgoCD app)
    ├── grafana.yaml           # Grafana deployment + ingress
    ├── argocd-ingress.yaml    # ArgoCD ingress with TLS
    └── argocd-config.yaml     # ArgoCD insecure mode for Traefik
```

**ArgoCD connects automatically to this repo and deploys all manifests.**

## Monitoring

Grafana is connected to two data sources:

- **CloudWatch** — EC2 CPU, estimated AWS billing costs
- **Prometheus** — Kubernetes pod health, node CPU/memory, network traffic

## Notes

- k3s includes Traefik as the default ingress controller
- cert-manager uses HTTP01 challenge via Traefik for domain verification
- ArgoCD runs in insecure mode —> TLS termination handled by Traefik
