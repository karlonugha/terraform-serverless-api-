# Serverless URL Shortener — Lambda + API Gateway + DynamoDB

A serverless API built with Terraform that shortens URLs and redirects users.
No servers to manage, scales automatically, and costs virtually nothing.

## Architecture

```
Internet
   │
   ▼
┌─────────────────────┐
│  API Gateway (HTTP)  │  ← Public REST API endpoint
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Lambda Function     │  ← Node.js 20 — runs your code on demand
│  (serverless)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  DynamoDB Table      │  ← NoSQL database — stores URL mappings
│  (serverless)        │
└─────────────────────┘
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | /shorten | Create a short URL |
| GET | /{code} | Redirect to original URL |
| GET | /health | Health check |

## What You'll Learn

| Concept | Where It's Used |
|---------|----------------|
| **Lambda Functions** | `modules/lambda/` — serverless compute |
| **API Gateway** | `modules/api_gateway/` — HTTP routing |
| **DynamoDB** | `modules/dynamodb/` — NoSQL database |
| **IAM Policies** | `modules/lambda/` — fine-grained permissions |
| **CloudWatch Logs** | Automatic — Lambda logs go here |
| **Terraform data archive** | Zipping Lambda code for deployment |

## Cost

This project is essentially free under AWS Free Tier:
- Lambda: 1M free requests/month
- API Gateway: 1M free calls/month (first 12 months)
- DynamoDB: 25 GB free storage, 25 read/write units

## Getting Started

```bash
terraform init
terraform plan
terraform apply

# Test it
curl -X POST https://<api-url>/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://github.com/karlonugha"}'

# Destroy when done
terraform destroy
```
