# Security Best Practices

## Overview

This document describes the security measures implemented across the infrastructure, application, and CI/CD pipeline.

## 1. Secrets Management

**Implementation:** AWS Secrets Manager

- Application secrets (API keys, database passwords) are stored in AWS Secrets Manager, not in environment variables, code, or Dockerfiles.
- The ECS task definition references secrets by ARN; at runtime the ECS agent injects them into the container as environment variables.
- Each environment has its own secret with an isolated namespace: `people-assignment/{env}/app-config`.
- The Secrets Manager recovery window is set to 0 days in dev (immediate cleanup) and 30 days in prod (accidental deletion protection).

**Terraform snippet (from `modules/secrets/main.tf`):**

```hcl
resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.project}/${var.environment}/${var.secret_name}"
  recovery_window_in_days = var.recovery_window_in_days
}
```

**ECS integration (from `modules/ecs/main.tf`):**

```hcl
secrets = [
  {
    name      = "APP_SECRET"
    valueFrom = var.secrets_arn
  }
]
```

## 2. Network Restriction

**Implementation:** VPC with public/private subnet separation and strict security groups.

| Resource     | Placement       | Inbound Rules                        | Outbound Rules            |
|-------------|-----------------|--------------------------------------|---------------------------|
| ALB          | Public subnets  | 80/443 from `0.0.0.0/0`             | Container port to ECS SG  |
| ECS Tasks    | Private subnets | Container port from ALB SG only      | All (for ECR, Secrets, etc.) |

Key points:
- ECS tasks have **no public IP addresses** -- they are only reachable through the ALB.
- The ALB security group restricts egress to only the ECS security group on the container port.
- The ECS security group restricts ingress to only the ALB security group.
- Private subnets route to the internet via NAT Gateway (for pulling images and accessing AWS APIs).

## 3. HTTPS / TLS

**Implementation:** ACM certificate on the Application Load Balancer.

- When an ACM certificate ARN is provided, the ALB creates an HTTPS listener on port 443 using TLS 1.3 (`ELBSecurityPolicy-TLS13-1-2-2021-06`).
- The HTTP listener (port 80) automatically redirects all traffic to HTTPS with a 301 status code.
- The certificate is optional for dev/staging (to avoid domain requirements) but should be mandatory for production.

**Terraform snippet (from `modules/alb/main.tf`):**

```hcl
resource "aws_lb_listener" "https" {
  count           = local.enable_https ? 1 : 0
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.acm_certificate_arn
  # ...
}
```

## 4. IAM Least Privilege

**Implementation:** Separate IAM roles with minimal permissions.

| Role                  | Purpose                           | Permissions                                                    |
|-----------------------|-----------------------------------|----------------------------------------------------------------|
| ECS Execution Role    | Used by the ECS agent             | ECR pull, CloudWatch Logs write, Secrets Manager read (scoped) |
| ECS Task Role         | Used by the running container     | CloudWatch Logs write only                                     |

- The Secrets Manager read permission is scoped to the specific secret ARN, not a wildcard.
- No `*` resource policies are used.

## 5. Container Image Security

- **ECR scan-on-push** is enabled; every pushed image is scanned for known CVEs.
- **Image tag immutability** is set to `IMMUTABLE` in production to prevent tag overwriting.
- **Lifecycle policy** automatically cleans up old images (10 in dev, 25 in prod).
- The Dockerfile uses `python:3.11-slim` as the base image (minimal attack surface).

## 6. Container Hardening

The Dockerfile implements several hardening practices:

```dockerfile
# Non-root user
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser
USER appuser

# Health check built into the image
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"
```

- The container runs as a non-root user (`appuser`).
- A `HEALTHCHECK` instruction enables Docker-level health monitoring.
- The `.dockerignore` excludes tests, caches, and `.git` from the image.

## 7. CI/CD Secrets

- AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) are stored in **GitHub Secrets**, never committed to the repository.
- Per-environment secrets are stored in **GitHub Environments** (dev, staging, prod), providing isolation.
- The prod environment can require **manual approval** via GitHub Environment protection rules before deployment proceeds.

## 8. Terraform State Security

- State files are stored in an S3 bucket with **server-side encryption** (`encrypt = true`).
- State locking uses S3 native lock files (`use_lockfile = true`) to prevent concurrent modifications.
- Each environment has an isolated state key (`dev/terraform.tfstate`, `staging/terraform.tfstate`, `prod/terraform.tfstate`).

## Checklist Summary

| Category             | Status |
|----------------------|--------|
| Secrets in Secrets Manager, not in code | Yes |
| Private subnets for compute | Yes |
| Security groups with least-privilege rules | Yes |
| HTTPS with TLS 1.3 (when cert provided) | Yes |
| HTTP-to-HTTPS redirect | Yes |
| IAM least privilege with scoped policies | Yes |
| ECR image scanning | Yes |
| Immutable tags in prod | Yes |
| Non-root container user | Yes |
| CI/CD secrets in GitHub Secrets | Yes |
| Encrypted Terraform state | Yes |
| State locking enabled | Yes |
