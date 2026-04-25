# AWS DevOps Lab - CI/CD Pipeline Design for Cloud Deployments

This project was built to practice real-world DevOps workflows using tools commonly used by engineering teams.
It focuses on automation, containerization, infrastructure as code, AWS-ready deployments, and monitoring.

# What this project includes
- CI pipeline with GitHub Actions
- Dockerized API application
- Terraform infrastructure on AWS
- Deployment to ECS Fargate
- Monitoring with Prometheus and Grafana
- Security scanning in CI
- Separate staging and production environments

# Tech Stack
- Node.js / Express
- Docker
- GitHub Actions
- Terraform
- AWS ECS Fargate
- AWS ECR
- AWS Application Load Balancer
- Prometheus
- Grafana

# CI/CD Flow
1. Code is pushed to GitHub
2. GitHub Actions runs linting and tests
3. Security scans run on source code and container image
4. Docker image is built and published
5. Deployment to staging environment
6. Health checks are executed
7. Manual approval for production
8. Production deployment

# Infrastructure
Provisioned with Terraform:

- VPC
- Public and Private Subnets
- Application Load Balancer
- ECS Cluster
- ECR Repository
- Auto Scaling
- IAM Roles

# Monitoring
Application metrics are exposed through `/metrics`.
Prometheus collects metrics such as:

- Request count
- Response time
- Error rate
- Container health

Grafana dashboards visualize performance and availability.

# Local Setup

```bash
git clone https://github.com/diegonunfio/aws-devops-lab.git
cd aws-devops-lab
docker compose up --build
