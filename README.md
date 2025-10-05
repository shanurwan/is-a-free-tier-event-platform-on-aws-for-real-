# Event-Driven AWS Platform (IaC + CI/CD + Observability)

A production-style, serverless platform you can deploy on a new or low-usage AWS account while staying inside free/always-free limits. It mirrors what DevOps/Platform Engineers do: Terraform modules, CI/CD with OIDC, observability/alerts, secure defaults, and ops automation—but without costly services. It demonstrate decoupling, reliability (DLQ), idempotency, and production ownership (dashboards/alarms) without ECS/Fargate or RDS costs.

## Feature
- Event ingestion → queue → worker → storage → notifications

- Terraform modules with env separation (dev, stage, prod)

- CI/CD (GitHub Actions) with OIDC (no long-lived AWS keys)

- Observability: CloudWatch metrics, logs, alarms, dashboards

- Cost safety: guardrails to keep usage inside free tiers


## Architecture

```
Client (curl/Postman)
        │
        ▼
Lambda Ingest (Function URL, Python)
  - auth optional, validate payload
  - add idempotency key
        │
        ▼
Amazon SQS (standard)
  - long polling, DLQ + redrive
        │
        ▼
Lambda Worker (Python)
  - idempotent processing
  - writes results to DynamoDB
  - stores blobs to S3 
  - publishes SNS ops message
        │
        ├──▶ DynamoDB (on-demand)
        ├──▶ S3 (versioned, lifecycle)
        └──▶ SNS (ops / follow-ons)

CloudWatch: structured logs, dashboard, alarms (SQS age, Lambda errors)
Billing: free-tier usage/budget alerts 

``` 

## Repo Layout

``` 
.
├─ README.md
├─ infra/
│  ├─ modules/
│  │  ├─ sqs/                     # queue + DLQ + IAM
│  │  ├─ lambda/                  # generic lambda + URLs, log policy
│  │  ├─ dynamodb/                # table + on-demand + kms
│  │  ├─ s3/                      # versioned + lifecycle
│  │  └─ sns/                     # topic + subscription(s)
│  └─ live/
│     ├─ dev/
│     │  ├─ main.tf
│     │  ├─ variables.tf
│     │  └─ backend.tf            # remote state (S3 + DynamoDB lock)
│     ├─ stage/
│     └─ prod/
├─ services/
│  ├─ ingest_lambda/              # Python + tests (pytest)
│  └─ worker_lambda/              # Python + tests (pytest)
├─ ci/
│  └─ github-actions/
│     └─ infra.yml                # plan/apply with OIDC; tfsec/tflint
├─ automation/
│  └─ drift_check/                #  plan -detailed-exitcode → SNS
└─ .pre-commit-config.yaml        # fmt, validate, tflint, tfsec hooks
```

## Prerequisites
- AWS account with IAM admin (for initial setup)

- Terraform ≥ 1.6

- Python 3.11 (for Lambdas + tests)

- GitHub repo (for Actions + OIDC)

- S3 bucket + DynamoDB table for Terraform remote state