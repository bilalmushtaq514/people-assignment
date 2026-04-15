# People Assignment -- DevOps Infrastructure

A production-ready DevOps setup featuring a Python Flask application deployed on AWS ECS Fargate, provisioned with modular Terraform, and automated with GitHub Actions CI/CD.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) v2, configured with appropriate credentials
- [Docker](https://www.docker.com/) for local image builds
- [Python](https://www.python.org/) 3.11+ for local development
- An AWS account with permissions to create VPC, ECS, ECR, ALB, IAM, Secrets Manager, and CloudWatch resources
- An S3 bucket for Terraform state (`people-assignment-tfstate`) -- create it beforehand:

```bash
aws s3 mb s3://people-assignment-tfstate --region us-east-1
```

## Project Structure

```
.
├── app/                        # Flask application + Dockerfile
├── terraform/
│   ├── modules/                # 8 reusable Terraform modules
│   └── environments/           # dev / staging / prod configs
├── .github/workflows/          # CI/CD pipeline
├── docs/                       # Monitoring & security documentation
├── REPORT.md                   # Full assignment report
└── README.md                   # This file
```

## Quick Start

### 1. Run the Application Locally

```bash
cd app
pip install -r requirements.txt
python app.py
# Visit http://localhost:5000
```

### 2. Run Tests

```bash
cd app
pip install -r requirements.txt
pytest tests/ -v
```

### 3. Build the Docker Image

```bash
cd app
docker build -t people-assignment-app .
docker run -p 5000:5000 people-assignment-app
```

### 4. Deploy Infrastructure

```bash
# Deploy the dev environment
cd terraform/environments/dev

# Initialize Terraform (downloads providers, configures backend)
terraform init

# Review the execution plan
terraform plan

# Apply the changes
terraform apply
```

Repeat for `staging` or `prod` by changing into the corresponding directory.

### 5. Push a Docker Image to ECR

After `terraform apply` completes, use the ECR repository URL from the output:

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build, tag, and push
docker build -t people-assignment-{ENV_NAME} app/
docker tag people-assignment-{ENV_NAME}:latest <ecr-repository-url>:latest
docker push <ecr-repository-url>:latest
```

### 6. Configure CI/CD

1. Push this repository to GitHub.
2. Create three GitHub Environments: `dev`, `staging`, `prod`.
3. Add these secrets to each environment:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (e.g., `us-east-1`)
   - `ECR_REPOSITORY` (e.g., `people-assignment-dev`)
   - `ECS_CLUSTER` (e.g., `people-assignment-dev-cluster`)
   - `ECS_SERVICE` (e.g., `people-assignment-dev-service`)
4. Add a **required reviewer** protection rule to the `prod` environment.

**Branching strategy:**

| Branch | Pipeline Behavior |
|--------|------------------|
| `main` | CI only (lint + test) |
| `dev` | CI + build + deploy to **dev** |
| `staging` | CI + build + deploy to **staging** |
| `prod` | CI + build + deploy to **prod** (requires approval) |
| PR to `main` | CI only (lint + test) |

### 7. Destroy Infrastructure

```bash
cd terraform/environments/dev
terraform destroy
```

## Environment Comparison

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| CPU / Memory | 256 / 512 MiB | 512 / 1024 MiB | 1024 / 2048 MiB |
| Task Count | 1 | 2 | 3 |
| NAT Gateway | Single | Single | Per-AZ |
| Log Retention | 7 days | 30 days | 90 days |
| ECR Max Images | 10 | 15 | 25 |
| Image Tags | Mutable | Mutable | Immutable |

## Documentation

- [docs/pipeline-steps.md](docs/pipeline-steps.md) -- CI/CD pipeline steps, trigger rules, and secrets reference
- [docs/monitoring-setup.md](docs/monitoring-setup.md) -- Monitoring and logging details
- [docs/security-practices.md](docs/security-practices.md) -- Security best practices implemented

## Terraform Module Reference

| Module | Path | Purpose |
|--------|------|---------|
| VPC | `terraform/modules/vpc/` | VPC, subnets, IGW, NAT Gateway, route tables |
| ECR | `terraform/modules/ecr/` | Container registry with scanning and lifecycle |
| Security Groups | `terraform/modules/security-groups/` | ALB and ECS security groups |
| IAM | `terraform/modules/iam/` | ECS execution and task roles |
| ALB | `terraform/modules/alb/` | Load balancer, target group, HTTP/HTTPS listeners |
| ECS | `terraform/modules/ecs/` | Fargate cluster, task definition, service |
| Secrets | `terraform/modules/secrets/` | AWS Secrets Manager |
| Monitoring | `terraform/modules/monitoring/` | CloudWatch logs, alarms, dashboard |
