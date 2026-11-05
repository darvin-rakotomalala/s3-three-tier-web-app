# Production-Grade S3 Three-Tier Web Application on AWS (Terraform)

A secure, highly available and auto-scaling three-tier web application on AWS, defined entirely as code with Terraform
and deployed through GitHub Actions using keyless (OIDC) authentication.

- **Presentation tier:** static frontend on Amazon S3, delivered through CloudFront with WAF protection
- **Application tier:** Java Spring Boot REST API on EC2 Auto Scaling instances in private subnets, behind an
  Application Load Balancer
- **Data tier:** Amazon RDS for PostgreSQL (Multi-AZ) in isolated database subnets

![Architecture diagram](s3-three-tier-web-app.png)

---

## 1. Overview

### Use case

A company is launching a customer-facing web portal for geographically distributed users. The platform must meet these
requirements:

| Requirement                                              | How the architecture addresses it                                        |
|:---------------------------------------------------------|:-------------------------------------------------------------------------|
| Low latency for users                                    | CloudFront edge caching in front of S3 and the ALB                       |
| Secure storage of customer and transactional data        | RDS PostgreSQL in isolated subnets, encrypted at rest with KMS           |
| Reliable static file storage                             | S3 with versioning and encryption                                        |
| Survive a server or Availability Zone failure            | Three AZs, Auto Scaling Group, Multi-AZ RDS, one NAT Gateway per AZ      |
| Scale automatically with traffic                         | Target-tracking scaling on CPU and ALB request count                     |
| Data protected at rest and in transit                    | KMS encryption everywhere, TLS 1.2+ on every hop                         |
| No unauthorized access                                   | Least-privilege IAM, chained security groups, WAF, no public app/DB tier |
| Limited budget                                           | Static hosting on S3, elastic compute, right-sized RDS, lifecycle rules  |
| Monitoring and logging of application and infrastructure | CloudWatch Logs, alarms, dashboards, VPC Flow Logs, CloudTrail, SNS      |

### Problems this project solves

| Problem                                                                                   | Solution                                                                                        |
|:------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------|
| Manual, error-prone deployments slow releases and add operational overhead                | Terraform for infrastructure and GitHub Actions for application and frontend delivery           |
| Static AWS access keys stored in third-party platforms risk leaks and unauthorized access | GitHub Actions authenticates to AWS with OpenID Connect (OIDC) and short-lived role credentials |
| Backend servers and database credentials exposed to the internet                          | Private subnets, security-group chaining and secrets pulled at runtime from Secrets Manager     |
| Paying for always-on compute to serve static content                                      | Frontend served from S3 and CloudFront                                                          |
| Downtime during traffic surges and no visibility into failures                            | Auto Scaling behind an ALB, plus CloudWatch alarms wired to SNS                                 |

### Key objectives

- **Availability:** target 99.95% uptime, with no single point of failure
- **Elasticity:** scale with peak and off-peak traffic
- **Low operational overhead:** managed services wherever possible
- **Security by design:** layered controls rather than a single perimeter

---

## 2. Architecture

### 2.1 Tiers and services

| Tier / concern     | Services and configuration                                                                                                                                                                                                                                    |
|:-------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Edge and DNS**   | Route 53 (hosted zone, alias records, DNSSEC), CloudFront (CDN), ACM (DNS-validated certificates), AWS WAF, AWS Shield Standard                                                                                                                               |
| **Presentation**   | S3 website bucket (versioning, SSE-S3), S3 ops bucket for custom error pages and logs, JavaScript client using Axios                                                                                                                                          |
| **Application**    | Java 21 / Spring Boot 4 REST API on EC2, launched from a launch template (Ubuntu LTS, Java 21, CloudWatch Agent, AWS CLI, SSM Agent). Auto Scaling Group in private subnets across 3 AZs, behind an internet-facing ALB. The application JAR is stored in S3. |
| **Data**           | RDS PostgreSQL (`db.r5.large`, Multi-AZ, KMS-encrypted) in isolated database subnets, reachable only from the application tier                                                                                                                                |
| **Networking**     | VPC `18.0.0.0/16`, Internet Gateway, 3 NAT Gateways, VPC Interface Endpoints (SSM, SSM Messages, EC2 Messages, Secrets Manager), S3 Gateway Endpoint with a bucket-restricted policy, VPC Flow Logs                                                           |
| **Security**       | IAM roles and instance profile, KMS customer-managed keys, Secrets Manager (30-day rotation), security groups, NACLs                                                                                                                                          |
| **Observability**  | CloudWatch Logs, metrics, alarms and dashboards, KMS-encrypted SNS email alerts, CloudTrail                                                                                                                                                                   |
| **Infrastructure** | Terraform, GitHub Actions, GitHub OIDC provider                                                                                                                                                                                                               |

### 2.2 Network layout

Region: `us-east-1`. VPC CIDR: `18.0.0.0/16`.

| Subnet tier     | AZ-a           | AZ-b           | AZ-c           | Hosts                            |
|:----------------|:---------------|:---------------|:---------------|:---------------------------------|
| **Public**      | `18.0.1.0/24`  | `18.0.2.0/24`  | `18.0.3.0/24`  | ALB, NAT Gateways (one per AZ)   |
| **Private app** | `18.0.11.0/24` | `18.0.12.0/24` | `18.0.13.0/24` | EC2 Auto Scaling instances       |
| **Database**    | `18.0.21.0/24` | `18.0.22.0/24` | n/a            | RDS primary and Multi-AZ standby |

### 2.3 Request flow

| # | Hop                          | What happens                                                                                                                   | Controls                                            |
|:--|:-----------------------------|:-------------------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------|
| 1 | **Client → Route 53**        | The client resolves `cloudwithdarvin.com` or `api.cloudwithdarvin.com`. Both are alias A records pointing to CloudFront.       | Hosted zone, DNSSEC                                 |
| 2 | **Route 53 → CloudFront**    | The request reaches the nearest edge location. HTTP is redirected to HTTPS and IPv6 is supported.                              | ACM certificate, TLS 1.2/1.3, `redirect-to-https`   |
| 3 | **CloudFront → origin**      | WAF inspects the request. Static content is served from the S3 website origin; API requests are forwarded to the ALB origin.   | WAF rules, cache policy per origin                  |
| 4 | **ALB → Auto Scaling Group** | The ALB, spread over three public subnets, picks a healthy target. Port 80 listeners redirect to HTTPS.                        | `alb-sg` (80/443), health checks, target group      |
| 5 | **EC2 (Spring Boot)**        | An instance in a private subnet handles the request. It accepts traffic from the ALB security group only and has no public IP. | `ec2-app-sg` (ingress from `alb-sg` only), NACLs    |
| 6 | **EC2 → RDS PostgreSQL**     | The application queries the database on port 5432. The database has no route to the internet.                                  | `rds-sg` (ingress from `ec2-app-sg` only), TLS, KMS |

The response returns along the same path in reverse. All logs flow to CloudWatch and all API activity is audited in
CloudTrail.

### 2.4 Supporting traffic

- **Outbound internet:** application instances reach the internet (package installs, updates) through the NAT Gateway
  in their own AZ. Nothing on the internet can initiate a connection to them.
- **Private AWS service calls:** instances reach Systems Manager, Secrets Manager (database password) and S3
  (application JAR) through VPC endpoints, so this traffic stays on the AWS network.
- **Administration:** operators connect through **SSM Session Manager** only. There is no bastion host, no SSH rule and
  no public IP on the application or database tiers.
- **Logs and metrics:** instances, the ALB and RDS publish to CloudWatch. Alarms notify the team through a
  KMS-encrypted SNS topic.

---

## 3. Security

Security is applied in independent layers, so a failure in one layer does not compromise the whole system.

### 3.1 Defense in depth

| Layer          | Services                                   | Purpose                                                |
|:---------------|:-------------------------------------------|:-------------------------------------------------------|
| **Edge**       | CloudFront, WAF, Shield Standard, DNSSEC   | DDoS protection and traffic filtering at the perimeter |
| **Network**    | VPC, security groups, NACLs, VPC endpoints | Isolation and traffic control                          |
| **Compute**    | SSM Session Manager, instance profile      | Managed access, no SSH, no public IPs                  |
| **Identity**   | IAM roles, OIDC, Secrets Manager           | No long-lived credentials anywhere                     |
| **Data**       | KMS, S3 / RDS / EBS encryption             | Encryption at rest for every data store                |
| **Monitoring** | CloudWatch, VPC Flow Logs, CloudTrail      | Audit logging and detection                            |

### 3.2 Network boundaries

Each tier accepts traffic only from the tier directly in front of it.

| Boundary               | Allowed in                             | Everything else |
|:-----------------------|:---------------------------------------|:----------------|
| Public subnets (ALB)   | 80/443 from the internet (`alb-sg`)    | Denied          |
| App subnets (EC2)      | Application traffic from `alb-sg` only | Denied          |
| Database subnets (RDS) | 5432 from `ec2-app-sg` only            | Denied          |

### 3.3 Zero-trust principles applied

- **Identity over network location:** services authenticate through IAM roles, not IP allow-lists
- **Least privilege:** each resource has its own narrowly scoped role or security group
- **Micro-segmentation:** security groups permit only the specific flows each service needs
- **Private connectivity:** AWS service traffic uses VPC endpoints rather than the public internet
- **Assume breach:** private tiers, encrypted data and continuous monitoring limit the blast radius
- **Encrypt everything:** TLS on every connection

### 3.4 Identity, access and secrets

- EC2 uses an **instance profile** with least-privilege access to S3, SSM, Secrets Manager, KMS and CloudWatch
- GitHub Actions assumes a limited IAM role through an **OIDC provider**, so no access keys exist
- Database credentials live in **Secrets Manager**, are encrypted with KMS, rotate every **30 days**, and are read by
  the
  application at runtime. No credentials appear in code.
- Access to secrets is logged in CloudTrail

### 3.5 Encryption

| Scope          | Mechanism                                                                                                                                                                      |
|:---------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **At rest**    | RDS, Secrets Manager, CloudWatch Logs and SNS use KMS customer-managed keys. S3 uses SSE-S3 (website content) or SSE-KMS (sensitive data). Keys are separated per environment. |
| **In transit** | User ↔ CloudFront and CloudFront ↔ ALB use HTTPS (TLS 1.2/1.3) with ACM certificates. App ↔ RDS uses TLS (`require_secure_transport` enforced).                                |

### 3.6 AWS WAF

WAF is attached to CloudFront and covers common web threats (SQL injection, XSS, path traversal, command injection,
bots):

- Rate limit: 2000 requests per 5 minutes per IP
- AWS managed rule groups for SQL injection, XSS and known bad inputs
- AWS IP reputation list
- Optional geo-blocking and bot detection

### 3.7 DDoS protection

AWS Shield Standard (always on) and CloudFront absorb layer 3/4 attacks. WAF rate limiting handles application-layer
floods, and Auto Scaling absorbs legitimate spikes.

---

## 4. High Availability and Scaling

### 4.1 High availability

| Component             | Strategy                                                                          |
|:----------------------|:----------------------------------------------------------------------------------|
| Compute               | Instances spread across 3 AZs (`us-east-1a`, `1b`, `1c`)                          |
| Load balancer         | ALB across 3 public subnets, cross-zone load balancing, health checks             |
| Database              | RDS Multi-AZ with automatic failover to a synchronous standby                     |
| Egress                | One NAT Gateway per AZ, so an AZ failure does not remove egress for the others    |
| Self-healing          | The Auto Scaling Group replaces failed instances in the same AZ                   |
| Zero-downtime updates | Instance refresh on launch-template changes, keeping a minimum healthy percentage |

### 4.2 Auto Scaling (application tier)

| Setting       | Value                                                                 |
|:--------------|:----------------------------------------------------------------------|
| Capacity      | Min 2, desired 2, max 6 instances                                     |
| Policies      | Target tracking on average CPU (70%) and ALB request count per target |
| Health checks | ALB target-group health checks                                        |

### 4.3 Scaling the other layers

- **Database:** vertical scaling through larger instance classes, read replicas for read-heavy workloads
- **Storage:** S3 scales without provisioning
- **Content:** CloudFront caches frequently requested content close to users

---

## 5. Monitoring and Logging

Monitoring shows *what* is happening; logs explain *why*. Both are centralized in CloudWatch.

| Source      | Metrics and alarms                                                   | Logs                               |
|:------------|:---------------------------------------------------------------------|:-----------------------------------|
| **EC2**     | CPU utilization, network traffic, status checks                      | Application, error and system logs |
| **ALB**     | Request count, target response time, HTTP 4xx/5xx, unhealthy targets | Access logs                        |
| **RDS**     | CPU, connections, free storage, read/write latency                   | Database logs                      |
| **Network** | n/a                                                                  | VPC Flow Logs                      |
| **Account** | n/a                                                                  | CloudTrail (90-day retention)      |

- Application log groups use a **30-day** retention
- CloudWatch alarms publish to a **KMS-encrypted SNS topic** with an email subscription
- Dashboards give real-time visibility across the ALB, application tier and RDS

**Troubleshooting workflow:** `Alert → check metrics → check logs → identify root cause → fix → verify → document`.

---

## 6. CI/CD

```
Developer push → GitHub → GitHub Actions → OIDC → temporary IAM role → AWS
```

When code is pushed, a GitHub Actions workflow requests short-lived credentials from AWS through OIDC. The assumed IAM
role has only the permissions needed to deploy.

| Workflow             | Purpose                                                                           |
|:---------------------|:----------------------------------------------------------------------------------|
| `checkov.yml`        | Scans Terraform for misconfigurations on the repository and on every pull request |
| `deploy_infra.yml`   | Provisions the infrastructure with Terraform                                      |
| `deploy_backend.yml` | Deploys the Spring Boot JAR from S3 to the EC2 instances                          |

---

## 7. Prerequisites

- Terraform >= 1.14
- AWS CLI v2 configured with valid credentials
- JDK 21+ and Maven 3.6+
- AWS Session Manager plugin
- Git
- A domain hosted in Route 53 (this project uses `cloudwithdarvin.com`)

---

## 8. Deployment

### 8.1 Provision the infrastructure

```bash
git clone <repository-url>
cd s3-three-tier-web-app/terraform

$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="terraform.tfvars" -auto-approve
```

![Terraform outputs](Screenshot%20verification/1-Outputs.png)

### 8.2 Move state to a remote backend (recommended)

1. Enable the backend configuration in `terraform/backend.tf`
2. Migrate the state: `terraform init -migrate-state`

### 8.3 Deploy through GitHub Actions

Push to the repository to run the workflows described in [CI/CD](#6-cicd). The infrastructure and application are
deployed by `deploy_infra.yml` and `deploy_backend.yml`.

---

## 9. Verification and Testing

Technical specifications are in the `Documentation` directory and all screenshots are in `Screenshot verification`.
After deployment, the site is live at `https://cloudwithdarvin.com/` over a verified HTTPS connection.

### 9.1 API endpoints

| Method | Endpoint                                                    | Description                                         |
|--------|-------------------------------------------------------------|-----------------------------------------------------|
| GET    | `https://api.cloudwithdarvin.com/health`                    | Health Check Endpoint                               |
| POST   | `https://api.cloudwithdarvin.com/tutorials`                 | Create a new Tutorial                               |
| GET    | `https://api.cloudwithdarvin.com/tutorials`                 | Retrieve all Tutorials                              |
| GET    | `https://api.cloudwithdarvin.com/tutorials/:id`             | Retrieve a Tutorial by `:id`                        |
| PUT    | `https://api.cloudwithdarvin.com/tutorials/:id`             | Update a Tutorial by `:id`                          |
| DELETE | `https://api.cloudwithdarvin.com/tutorials/:id`             | Delete a Tutorial by `:id`                          |
| DELETE | `https://api.cloudwithdarvin.com/tutorials`                 | Delete all Tutorials                                |
| GET    | `https://api.cloudwithdarvin.com/tutorials/published`       | Find all published Tutorials                        |
| GET    | `https://api.cloudwithdarvin.com/tutorials?title=[keyword]` | Find all Tutorials whose title contains the keyword |

### 9.2 Resilience tests ("break and fix")

#### Self-healing: terminate an instance

1. In the console, select an instance and choose **Instance state → Terminate instance**.
2. Refresh the application URL. Traffic is now served by the one remaining instance.
3. Open the Auto Scaling group's activity history to see the replacement launch.
4. A new instance starts in the **same Availability Zone** as the terminated one.
5. Once healthy, it joins the ALB target group and receives traffic (*EC2 → Load Balancing → Target Groups*).

This works because the Auto Scaling group's `desired_capacity` is 2. Unlike a standalone EC2 instance, the group
replaces the failed instance and registers it with the load balancer automatically.

#### Scale-out and scale-in: target tracking

Generate roughly 100 requests per second (20 workers × 5 requests per second) for 15 minutes with
[`hey`](https://github.com/rakyll/hey):

```bash
hey -z 15m -c 20 -q 5 https://api.cloudwithdarvin.com/health
```

After about 10 to 15 minutes the policy added instances, reaching the configured **maximum of 6**. No further instances
are launched beyond that cap, even under high CPU. After health checks pass, the ALB routes traffic to all instances.

When the load stops, instances are removed one by one until the group returns to the desired capacity. Without a
scale-in policy the group would stay large and defeat the purpose of auto scaling.

#### Scale-out: CPU stress test

The `user_data` script installs the `stress` utility. Connect to any instance through Session Manager and run:

```bash
nohup stress --cpu "$(nproc)" --timeout 900 > /tmp/stress.log 2>&1 &
```

---

## 10. Cost Optimization

The goal is not the lowest cost but the required availability, security and performance within the business budget.
Figures below are indicative; validate them with the AWS Pricing Calculator.

| Area              | Practice                                                                                    | Indicative saving          |
|:------------------|:--------------------------------------------------------------------------------------------|:---------------------------|
| **Compute**       | Start with the required capacity and let Auto Scaling add more only when needed             | n/a                        |
| **Commitments**   | 1-year, no-upfront Reserved Instances for RDS and EC2, or Compute Savings Plans             | Up to ~40% (RI), ~50% (SP) |
| **Right-sizing**  | Review CloudWatch metrics over 30 days and downsize underused resources                     | ~10–15%                    |
| **Networking**    | Use a single NAT Gateway in non-production environments (production keeps one per AZ)       | ~$32.85/month              |
| **Non-prod size** | Use `t3.small` instances outside production                                                 | ~$30/month per instance    |
| **Dev schedule**  | Stop development resources nights and weekends                                              | ~50% of dev cost           |
| **Storage**       | S3 lifecycle policies (Standard → Infrequent Access → Glacier), media in S3 rather than EBS | ~$15–20/month              |
| **Delivery**      | CloudFront caching reduces repeated origin requests                                         | n/a                        |
| **Governance**    | Cost Explorer, budget alerts at 80%, remove unused resources                                | n/a                        |

**---

## 11. Well-Architected Alignment

| Pillar                     | Implementation                                                                                                            |
|:---------------------------|:--------------------------------------------------------------------------------------------------------------------------|
| **Operational Excellence** | Terraform-managed infrastructure in Git, CI/CD with Checkov scanning, CloudWatch dashboards, SNS alerting                 |
| **Security**               | Least-privilege IAM, OIDC for CI/CD, KMS encryption, TLS 1.2+, Secrets Manager rotation, WAF, private subnets, CloudTrail |
| **Reliability**            | Three AZs, Multi-AZ RDS, ALB health checks, Auto Scaling self-healing, instance refresh                                   |
| **Performance Efficiency** | CloudFront edge caching, auto scaling on live metrics, read replicas for read-heavy workloads                             |
| **Cost Optimization**      | Elastic capacity, static hosting on S3, S3 lifecycle rules, Savings Plans and Reserved Instances, budget alerts           |
| **Sustainability**         | No idle over-provisioning, managed services, 30-day log retention, lifecycle archival                                     |

### Success criteria

- Availability target of 99.95% across multiple AZs
- Handles 10x traffic growth without architectural change
- Zero data loss on database failover (Multi-AZ synchronous replication)
- Passes a security review with no critical findings
- Cost and recovery objectives (RTO/RPO) defined per environment (dev, staging, production)**

---

## 12. Next Improvements

This release delivers the core three-tier foundation. Planned enhancements:

**Resilience and disaster recovery**

- **RDS backups:** daily automated backups (7-day retention), weekly manual snapshots (30-day retention), daily
  cross-region snapshot copy to `us-west-2`, managed with AWS Backup
- **S3 protection:** versioning on all buckets, cross-region replication of critical buckets, Glacier transition after
  365 days
- **DR region** (`us-west-2`): standby database replica, S3 replication, AMI backups
- **Failover:** Route 53 health checks with DNS failover (TTL 60 s), automatic RDS failover (30–120 s), ALB health
  checks removing unhealthy targets (about 30 s)
- Define **RPO** (how much data can be lost) and **RTO** (how quickly service must return) per environment, and size
  the backup strategy to those targets rather than taking as many backups as possible

**Platform**

- Amazon EFS for shared storage across application servers
- ElastiCache for Redis (cluster mode) for session and data caching, with automatic node replacement
- Route 53 geolocation routing for a multi-region setup

**Security**

- Amazon Cognito for authentication
- GuardDuty, Security Hub, AWS Config and Inspector for continuous detection and compliance

**Operations**

- Blue-green or canary deployments with automated rollback
- CloudWatch Synthetics for external monitoring
- Off-hours scheduler (Lambda) for non-production environments
- Documented runbooks and periodic failover game days

---

## 13. Cleanup

Destroy all resources to stop charges:

```bash
terraform destroy -var-file="terraform.tfvars" -auto-approve"
```

---

## Summary

The platform recovers from instance failure on its own, adds and removes capacity as load changes, and keeps the
application servers and database off the public internet. All infrastructure is defined in Terraform, delivered through
GitHub Actions with keyless OIDC authentication, and designed around the Well-Architected pillars from the start.

The design began with business requirements and mapped each one to a managed AWS service:

| Need                    | Service                 |
|:------------------------|:------------------------|
| Network isolation       | VPC                     |
| Traffic distribution    | ALB                     |
| Scalable compute        | EC2 Auto Scaling        |
| Relational data and HA  | RDS PostgreSQL Multi-AZ |
| Static website          | S3                      |
| Low-latency delivery    | CloudFront              |
| DNS                     | Route 53                |
| TLS certificates        | ACM                     |
| Encryption              | KMS                     |
| Controlled access       | IAM                     |
| Monitoring and alerting | CloudWatch, SNS         |
