# Technical Specification: Scalable Three-Tier Web Application on AWS (Terraform)

> **Scope**:  Route 53 → CloudFront + WAF → S3/ALB → EC2 Auto Scaling (Spring Boot) → RDS PostgreSQL.

## 1. Purpose and Scope

This document specifies the design, build and deployment of a production-grade, three-tier web application on AWS. All
infrastructure is provisioned with Terraform and delivered through GitHub Actions using keyless (OIDC) authentication.

The platform must be resilient to Availability Zone (AZ) failures, isolated at the network level, built on
least-privilege access, fully automated, and cost-conscious. It is intended to mirror enterprise requirements, not a
single-instance demo.

**In scope:** networking, edge delivery and security, compute, database, secrets and encryption, observability, CI/CD
and Terraform state management, backup and cost controls.

**Out of scope:** application business logic and multi-region active-active deployment (see section 14, Future
Enhancements).

## 2. Business Context

### 2.1 Use case

A company is launching a customer-facing web portal for users across Africa. The portal stores customer and
transactional data, serves static content, and must remain available and affordable as traffic grows.

### 2.2 Problems addressed

| Problem                                       | Impact                                           | How this design addresses it                                                      |
|:----------------------------------------------|:-------------------------------------------------|:----------------------------------------------------------------------------------|
| Manual, error-prone deployments               | Slow releases, human error, operational overhead | Terraform plus GitHub Actions pipelines; instance refresh for rolling releases    |
| Static cloud credentials in third-party tools | Credential leaks, unauthorized access            | GitHub OIDC with short-lived IAM role credentials; no IAM user keys anywhere      |
| Backend or database exposed to the internet   | Data breach risk                                 | Private app and database subnets; only the ALB and CloudFront are internet-facing |
| Static content on always-on compute           | Unnecessary cost                                 | Static site on S3 behind CloudFront                                               |
| No elasticity or monitoring                   | Downtime during traffic surges, lost user trust  | Auto Scaling behind an ALB; CloudWatch alarms routed to SNS                       |

### 2.3 Requirements

| ID  | Requirement                                                 | Design response                                                          |
|:----|:------------------------------------------------------------|:-------------------------------------------------------------------------|
| R1  | Low latency for users                                       | CloudFront edge caching; ALB and compute in the nearest practical region |
| R2  | Secure relational storage for customer and transaction data | RDS PostgreSQL, Multi-AZ, KMS-encrypted, private subnets                 |
| R3  | Efficient data retrieval                                    | Read replica for read-heavy queries; optional ElastiCache layer (see 14) |
| R4  | Reliable static file storage                                | S3 with versioning and encryption                                        |
| R5  | Survive instance or AZ failure                              | Three AZs; Auto Scaling; Multi-AZ database; one NAT Gateway per AZ       |
| R6  | Automatic scaling                                           | Target-tracking policies on CPU and ALB request count                    |
| R7  | Encryption at rest and in transit                           | KMS customer-managed keys; TLS 1.2/1.3 on every hop                      |
| R8  | Block unauthorized access                                   | WAF, security groups, NACLs, IAM least privilege, SSM-only admin access  |
| R9  | Limited budget                                              | Serverless static tier, S3 lifecycle tiering, right-sized instances      |
| R10 | Monitoring and logging                                      | CloudWatch, CloudTrail, VPC Flow Logs, SNS alerts                        |

### 2.4 Service-level objectives

| Objective    | Target                                                                        |
|:-------------|:------------------------------------------------------------------------------|
| Availability | 99.95% monthly uptime                                                         |
| Elasticity   | Scale automatically between peak and off-peak load without service disruption |
| Operations   | Minimize manual effort through managed services and automation                |

## 3. Architecture

### 3.1 Summary

The design follows the classic three-tier pattern, split into presentation, application and data tiers, with a shared
edge, security and observability layer.

| Tier / Layer      | Services                                                | Notes                                           |
|:------------------|:--------------------------------------------------------|:------------------------------------------------|
| **Edge**          | Route 53, CloudFront, AWS WAF, AWS Shield Standard, ACM | Global entry point; TLS, caching and filtering  |
| **Presentation**  | S3 (static site, private origin)                        | JavaScript front end using Axios as HTTP client |
| **Application**   | ALB, EC2 Auto Scaling group (Java Spring Boot)          | Private subnets, three AZs                      |
| **Data**          | RDS PostgreSQL (Multi-AZ), read replica                 | Isolated database subnets                       |
| **Security**      | IAM, KMS, Secrets Manager, VPC endpoints                | Keyless access and encryption everywhere        |
| **Observability** | CloudWatch, VPC Flow Logs, CloudTrail, SNS              | Centralized logs, alarms, dashboards            |
| **Delivery**      | GitHub, GitHub Actions, OIDC, Terraform                 | Remote state in S3 with DynamoDB locking        |

### 3.2 Design principles

- **Availability:** no single point of failure; every tier spans three AZs.
- **Security by default:** each tier accepts traffic only from the tier directly in front of it.
- **Repeatability:** everything is code; no console changes.
- **Least privilege:** scoped IAM roles, security groups referenced by ID, and per-environment KMS keys.
- **Cost awareness:** pay-per-use where possible, lifecycle policies on logs and artifacts.
- **Operability:** every component emits logs and metrics, and every critical condition raises an alert.

### 3.3 Request flow

| #  | Hop                      | What happens                                                                                           | Controls                                                                |
|:---|:-------------------------|:-------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------|
| 1  | Client → Route 53        | The domain and the `api` subdomain resolve through alias A records to CloudFront.                      | Hosted zone, DNSSEC                                                     |
| 2  | Route 53 → CloudFront    | The request reaches the nearest edge location. HTTP is redirected to HTTPS; IPv6 is supported.         | ACM certificate, TLS 1.2/1.3, `redirect-to-https`, WAF Web ACL          |
| 3a | CloudFront → S3          | Static content is fetched from the private website bucket on a cache miss.                             | Origin Access Control (SigV4), bucket policy scoped to the distribution |
| 3b | CloudFront → ALB         | API requests are forwarded to the ALB origin using a no-cache or short-cache policy.                   | Origin protection (see 5.4), HTTPS to origin                            |
| 4  | ALB → Auto Scaling group | The ALB, spread over three public subnets, selects a healthy target. HTTP listeners redirect to HTTPS. | `alb-sg`, health checks, target group                                   |
| 5  | EC2 (Spring Boot)        | An instance in a private subnet handles the request. It has no public IP.                              | `ec2-app-sg` (ingress from `alb-sg` only), NACLs                        |
| 6  | EC2 → RDS PostgreSQL     | The app queries the Multi-AZ database on port 5432.                                                    | `rds-sg` (ingress from `ec2-app-sg` only), TLS in transit, KMS at rest  |

The response returns along the same path in reverse. All logs flow to CloudWatch and all API activity is audited in
CloudTrail.

**Supporting (non-user) traffic**

- **Outbound internet:** app instances reach package repositories through the NAT Gateway in their own AZ. Nothing on
  the internet can initiate a connection to them.
- **Private AWS calls:** Systems Manager, Secrets Manager and S3 are reached through VPC endpoints and stay on the AWS
  network.
- **Administration:** operators use SSM Session Manager only. There is no bastion host, no SSH rule and no public IP on
  the app or database tiers.
- **Telemetry:** instances, the ALB and RDS send logs and metrics to CloudWatch; alarms notify the team through a
  KMS-encrypted SNS topic.

### 3.4 Security boundaries

| Boundary                  | Allowed in                             | Everything else |
|:--------------------------|:---------------------------------------|:----------------|
| Public subnets (ALB, NAT) | 80/443 from the internet               | Denied          |
| App subnets (EC2)         | Application traffic from `alb-sg` only | Denied          |
| Database subnets (RDS)    | 5432 from `ec2-app-sg` only            | Denied          |

A compromise at one layer cannot reach past the next.

### 3.5 Component catalogue

| Component                                          | Purpose                                                  |
|:---------------------------------------------------|:---------------------------------------------------------|
| GitHub repository and GitHub Actions               | Source control and automated build/deploy                |
| OIDC provider and deployment IAM role              | Keyless, short-lived credentials for the pipeline        |
| Route 53                                           | DNS, DNSSEC, health checks                               |
| ACM                                                | TLS certificates (CloudFront certificate in `us-east-1`) |
| CloudFront                                         | CDN for the static site and API origin                   |
| AWS WAF and Shield Standard                        | Request filtering and DDoS protection                    |
| S3 website bucket                                  | Private static front-end origin                          |
| S3 ops bucket                                      | CloudFront access logs and custom error pages            |
| S3 artifact bucket                                 | Spring Boot JAR consumed by instances at boot            |
| VPC, subnets, route tables, NACLs, security groups | Network isolation and traffic control                    |
| NAT Gateways, Internet Gateway                     | Controlled outbound and inbound connectivity             |
| VPC endpoints                                      | Private access to SSM, Secrets Manager and S3            |
| ALB and target group                               | Load balancing and health-based routing                  |
| Launch template and Auto Scaling group             | Elastic, self-healing compute                            |
| RDS PostgreSQL                                     | Managed relational database                              |
| Secrets Manager                                    | Database credentials with rotation                       |
| KMS                                                | Customer-managed encryption keys                         |
| IAM instance profile                               | Least-privilege access for EC2                           |
| CloudWatch, VPC Flow Logs, CloudTrail, SNS         | Logging, metrics, audit and alerting                     |
| AWS Backup                                         | Centralized backup and long-term retention               |

## 4. Network Design

### 4.1 VPC and subnets

One VPC (`18.0.0.0/16`, DNS support and hostnames enabled) spans three AZs in the primary region (`us-east-1`). Each AZ
holds one subnet per tier.

| Tier           | Purpose           | AZ-a         | AZ-b         | AZ-c         | Internet path                     |
|:---------------|:------------------|:-------------|:-------------|:-------------|:----------------------------------|
| Public         | ALB, NAT Gateways | 18.0.1.0/24  | 18.0.2.0/24  | 18.0.3.0/24  | Internet Gateway                  |
| Private (app)  | Spring Boot EC2   | 18.0.11.0/24 | 18.0.12.0/24 | 18.0.13.0/24 | Outbound only, via NAT in same AZ |
| Private (data) | RDS PostgreSQL    | 18.0.21.0/24 | 18.0.22.0/24 | 18.0.23.0/24 | None (no NAT, no IGW route)       |

- Three NAT Gateways, one per AZ with its own Elastic IP, so an AZ failure does not cut outbound access for the others.
- A DB subnet group spans the three data subnets.
- VPC Flow Logs are delivered to CloudWatch Logs.

### 4.2 Route tables

| Route table      | Associated subnets | Routes                                                                      |
|:-----------------|:-------------------|:----------------------------------------------------------------------------|
| Public           | Public subnets     | `0.0.0.0/0` → Internet Gateway                                              |
| App (one per AZ) | App subnets        | `0.0.0.0/0` → NAT Gateway in the same AZ; S3 prefix list → Gateway endpoint |
| Data             | Data subnets       | Local routes only                                                           |

### 4.3 Security groups

Rules are defined with standalone rule resources (`aws_vpc_security_group_ingress_rule` / `egress_rule`) rather than
inline blocks, to avoid circular dependencies. Rules reference other security groups instead of IP ranges wherever
possible, and every rule carries a description.

| Security group                  | Inbound                                                                                                            | Outbound                                       |
|:--------------------------------|:-------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------|
| `alb-sg`                        | 80 and 443 from the internet (or from the CloudFront managed prefix list; see 5.4). Port 80 only redirects to 443. | App port to `ec2-app-sg`                       |
| `ec2-app-sg`                    | App port from `alb-sg` only                                                                                        | 5432 to `rds-sg`; 443 to VPC endpoints and NAT |
| `rds-sg`                        | 5432 from `ec2-app-sg` only                                                                                        | None required                                  |
| `vpce-sg` (interface endpoints) | 443 from the VPC CIDR                                                                                              | None required                                  |

### 4.4 Network ACLs (defense in depth)

| NACL           | Inbound                                                                              | Outbound                                                 |
|:---------------|:-------------------------------------------------------------------------------------|:---------------------------------------------------------|
| Public subnets | 80 and 443 from the internet; ephemeral ports 1024-65535 for return traffic          | Ephemeral ports to the internet; app port to app subnets |
| App subnets    | App port from public subnets; ephemeral return traffic; no inbound from the internet | 5432 to data subnets; 443 to endpoints and NAT           |
| Data subnets   | 5432 from app subnet CIDRs only; deny everything else                                | Ephemeral return traffic to app subnets                  |

### 4.5 VPC endpoints

| Endpoint                            | Type      | Purpose                                                                            |
|:------------------------------------|:----------|:-----------------------------------------------------------------------------------|
| `ssm`, `ssmmessages`, `ec2messages` | Interface | Session Manager and SSM Agent without internet access                              |
| `secretsmanager`                    | Interface | Read the database credential                                                       |
| `s3`                                | Gateway   | Fetch the application JAR; endpoint policy restricts access to the artifact bucket |

Interface endpoints use `vpce-sg` and are deployed in the app subnets.

## 5. Edge and Content Delivery

### 5.1 DNS (Route 53)

- A public hosted zone is the authoritative zone for the domain; nameservers are set at the registrar.
- **DNSSEC** is enabled using an asymmetric KMS key as the Key Signing Key. Setup order: create the KMS key, grant Route
  53 use of it, create the KSK, activate DNSSEC, then publish the DS record at the registrar.
- Alias A records point the root domain, `www` and `api` to CloudFront.
- Route 53 health checks monitor the API endpoint and feed an alarm (see 9).

### 5.2 TLS certificates (ACM)

- Public certificate covering the root, `www` and `api` names, validated by DNS.
- CloudFront requires the certificate in **`us-east-1`**.
- Flow: request certificate → create the validation CNAME records in Route 53 → wait for validation → attach to
  CloudFront.
- Minimum TLS policy: TLS 1.2, with TLS 1.3 enabled.
- The ALB uses its own regional ACM certificate for the CloudFront-to-ALB HTTPS connection.

### 5.3 Static site storage (S3)

The presentation tier is a static JavaScript site stored in S3. It is **private** and reachable only through CloudFront,
so the public S3 website endpoint is not used.

**Website bucket:** randomized unique name; versioning on; encryption with KMS (customer-managed key); all four Block
Public Access settings on; bucket policy grants `s3:GetObject` to the CloudFront service principal scoped to the
distribution ARN.

**Ops bucket:** holds custom error pages (`error-pages/`) and CloudFront access logs (`logs/`). Block Public Access
leaves ACLs allowed because CloudFront standard logging writes through ACLs; policy-based public access stays blocked.
The bucket policy allows `s3:GetObject` on `error-pages/*` and `s3:PutObject` on `logs/*` for CloudFront.

**Lifecycle rules (ops bucket)**

| Rule                       | Scope          | Behavior                                                                 |
|:---------------------------|:---------------|:-------------------------------------------------------------------------|
| `abort_incomplete_uploads` | Whole bucket   | Cancel stalled multipart uploads after 7 days                            |
| `manage_log_files`         | `logs/`        | Standard → Standard-IA at day 30 → Glacier at day 90 → delete at day 365 |
| `manage_error_pages`       | `error-pages/` | No expiration; incomplete uploads cleaned after 7 days                   |

`force_destroy = true` is allowed in dev and staging only; it must be `false` in production.

### 5.4 CloudFront distribution

One distribution with aliases for the root, `www` and `api` names, default root object `index.html`, IPv6 enabled, HTTP
redirected to HTTPS, the WAF Web ACL attached, and optional geo-restriction driven by a variable.

**Origins**

| Origin         | Used for                                  | Access control                                                                                                                                       |
|:---------------|:------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
| Website bucket | Static content                            | Origin Access Control (SigV4, `s3` type)                                                                                                             |
| Ops bucket     | Error pages                               | Origin Access Control (SigV4, `s3` type)                                                                                                             |
| ALB            | API traffic (`/api/*` and the `api` host) | Secret custom header validated at the ALB, plus the CloudFront managed prefix list on `alb-sg`. Origin Access Control does not apply to ALB origins. |

**Cache behaviors (evaluated in order; first match wins)**

| Order   | Path pattern                                                                                   | Origin         | Cache policy                                                             |
|:--------|:-----------------------------------------------------------------------------------------------|:---------------|:-------------------------------------------------------------------------|
| 1       | `/assets/img/*` (including the `bg`, `misc`, `portfolio`, `profile` and `services` subfolders) | Website bucket | `static_assets`                                                          |
| 2       | `/assets/css/*.css`                                                                            | Website bucket | `static_assets`                                                          |
| 3       | `/assets/js/*.js`                                                                              | Website bucket | `static_assets`                                                          |
| 4       | `/assets/vendor/*`                                                                             | Website bucket | `static_assets`                                                          |
| 5       | `/error-pages/*`                                                                               | Ops bucket     | `static_assets`                                                          |
| 6       | `/api/*`                                                                                       | ALB            | Caching disabled (or short TTL), forwards auth headers and query strings |
| Default | Everything else (HTML)                                                                         | Website bucket | `html_content`                                                           |

**Cache policies**

| Policy          | Default TTL | Max TTL | Used for                      |
|:----------------|:------------|:--------|:------------------------------|
| `static_assets` | 1 day       | 1 year  | Images, CSS, JS, vendor files |
| `html_content`  | 1 hour      | 1 day   | HTML pages                    |

**Custom error responses**

| HTTP code | Page served             | Note                                                       |
|:----------|:------------------------|:-----------------------------------------------------------|
| 404       | `/error-pages/404.html` |                                                            |
| 403       | `/error-pages/404.html` | Treats forbidden as not found to avoid revealing structure |
| 500       | `/error-pages/500.html` |                                                            |

**Response headers policies:** the managed security-headers policy adds `Strict-Transport-Security` (1 year, including
subdomains), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` and a `Referrer-Policy`. A CORS policy permits
`GET`, `HEAD` and `OPTIONS`; the allowed origins should be the application's own domains rather than a wildcard. These
headers are a second line of defense in case a WAF rule is missing or wrong.

**Cache invalidation:** the pipeline invalidates only the changed paths after each deploy. A full `/*` invalidation is
reserved for complete releases and emergency fixes, because it forces every edge to refetch from the origin. Without
invalidation, stale HTML can be served for up to the policy TTL.

### 5.5 Web Application Firewall

A WAFv2 Web ACL with scope `CLOUDFRONT` is created in `us-east-1`, default action **allow**, with CloudWatch metrics and
sampled requests enabled on the ACL and on every rule.

| Priority | Rule                                        | Action                     | Purpose                                            |
|:---------|:--------------------------------------------|:---------------------------|:---------------------------------------------------|
| 1        | `AWSManagedRulesCommonRuleSet`              | Block (body-size override) | OWASP Top 10 style protections (XSS, bad requests) |
| 2        | `AWSManagedRulesKnownBadInputsRuleSet`      | Block                      | Known exploit patterns, including Log4Shell        |
| 3        | `RateLimitRule`                             | Block                      | More than 2,000 requests per 5 minutes per IP      |
| 4        | `AWSManagedRulesBotControlRuleSet` (COMMON) | Block                      | Common bots                                        |
| 5        | `AWSManagedRulesAmazonIpReputationList`     | Count                      | Observe bad-reputation IPs before blocking         |
| 6        | `AWSManagedRulesAnonymousIpList`            | Block                      | VPNs, Tor and proxies                              |
| 7        | `AWSManagedRulesSQLiRuleSet`                | Block                      | SQL injection                                      |
| 8        | `AWSManagedRulesLinuxRuleSet`               | Count                      | Linux-specific exploits (monitoring mode)          |
| 9        | `AWSManagedRulesUnixRuleSet`                | Count                      | Unix-specific exploits (monitoring mode)           |
| 10       | `AWSManagedRulesWindowsRuleSet`             | Block (shell override)     | Windows exploit protection                         |
| 11       | `block-bad-user-agents`                     | Block                      | Scanners such as sqlmap and nikto                  |

- An optional geo-match rule (disabled by default) can block or allow specific countries; IP allow and deny lists can be
  added as needed.
- **Rollout practice:** deploy new rules in `COUNT` mode for one to two weeks, review `CountedRequests` per rule, then
  switch to `BLOCK`.
- **Logging:** a log group named `aws-waf-logs-<prefix>` (the prefix is required by AWS), 7-day retention, sensitive
  fields redacted, filter keeps only `BLOCK` and `COUNT` events to control volume.
- AWS Shield Standard is included automatically for CloudFront and Route 53.

## 6. Application Tier

### 6.1 Application Load Balancer

- Internet-facing ALB across the three public subnets, protected by `alb-sg`.
- HTTPS listener (443) with the ACM certificate and a modern TLS policy; HTTP listener (80) redirects to HTTPS.
- Target group with health checks (path, interval and thresholds set in variables) attached to the Auto Scaling group.
- Access logs published to the log group `/aws/alb/spring-boot-app-alb` (see 9.3).

---

## 6.2 Amazon CloudFront for Application Load Balancer (ALB)

- Create a CloudFront web distribution for Application Load Balancer (ALB)
- Add CloudFront between Route 53 and ALB
- Create Origin Access Controls from ALB
- Origin Domain Name is Application Load Balancer
- Minimum Origin SSL Protocol, choose TLSv1.2
- Create CloudFront Distribution:
    - HTTPS enforced everywhere (redirect-to-https)
    - IPv6 enabled
- Create Cache Policies for Application Load Balancer (ALB)
- Use default cache behavior and Cache key and origin request
- For SSL Certificate, select Custom SSL Certificate. Then, add the ACM certificate for my domain
- Create a Route 53 record for the API path served through CloudFront. Use aliases `api.cloudwithdarvin.com`, used by
  the Application Load Balancer (ALB).
- Create Route 53 A Records for CloudFront: In this step, one alias A records will create — one for `api` — to point to
  the CloudFront distribution ──
  `api.cloudwithdarvin.com ── alias ──► CloudFront Distribution for Application Load Balancer (ALB)`

### 6.3 Compute (launch template and Auto Scaling group)

| Setting          | Value                                                                                                                                                                                   |
|:-----------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Name             | `spring-boot-server`                                                                                                                                                                    |
| AMI              | Ubuntu LTS                                                                                                                                                                              |
| Instance type    | `t3.large`                                                                                                                                                                              |
| Subnets          | App private subnets in three AZs                                                                                                                                                        |
| Security group   | `ec2-app-sg`                                                                                                                                                                            |
| Instance profile | App role (see 6.4)                                                                                                                                                                      |
| Monitoring       | Detailed (1-minute)                                                                                                                                                                     |
| Capacity         | Min 2, max 6 (see 15 for the proposed minimum)                                                                                                                                          |
| User data        | Install curl, AWS CLI, CloudWatch Agent, OpenJDK 21 and the PostgreSQL client; enable the SSM Agent; pull the JAR from S3; fetch DB credentials from Secrets Manager; start the service |

**Rolling releases:** the Auto Scaling group references the launch template ID and version, and its `instance_refresh`
block uses the `launch_template` trigger. A new AMI, instance type or user-data change therefore replaces instances
gradually while keeping healthy capacity. A `lifecycle { ignore_changes = [desired_capacity] }` block stops Terraform
from overriding scaling decisions on later applies.

**Scaling policies (dynamic, target tracking)**

| Policy                       | Target                                     | Notes                             |
|:-----------------------------|:-------------------------------------------|:----------------------------------|
| CPU utilization              | 70% average                                | Primary driver                    |
| ALB request count per target | Set from load testing                      | Handles request-driven bursts     |
| Memory utilization           | 80% (alarm; optional custom-metric policy) | Published by the CloudWatch Agent |

Target tracking creates both scale-out and scale-in behavior, so separate step policies are not used. Instance warm-up
is 60 seconds and scale-in is damped with a 300-second cooldown. Scale-in is expected once load stays below roughly 40%
for about 10 minutes.

### 6.4 Application delivery

The Spring Boot application is packaged as a JAR and stored in the private artifact bucket
`ce-dev-springboot-jar-bucket-69127` (SSE-KMS, versioned). The pipeline uploads a new JAR, then updates the launch
template to trigger an instance refresh. Instances download it through the S3 Gateway endpoint.

### 6.5 IAM role for EC2

One instance profile grants only what the application needs:

| Access          | Scope                                                         |
|:----------------|:--------------------------------------------------------------|
| S3 read         | The artifact bucket only                                      |
| Systems Manager | `AmazonSSMManagedInstanceCore` (Session Manager, Run Command) |
| Secrets Manager | `GetSecretValue` on the database secret only                  |
| KMS             | Decrypt on the keys for the secret and the log groups         |
| CloudWatch      | Write logs and metrics                                        |

RDS full access is not granted; the application reaches the database over the network with credentials from Secrets
Manager.

## 7. Data Tier

### 7.1 Primary database

| Setting               | Value                                                                                                                                              |
|:----------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------|
| Engine                | Amazon RDS for PostgreSQL, latest stable major version pinned in a variable (parameter group family `postgres16` in the current build)             |
| Instance class        | `db.r5.large` (2 vCPU, 8 GB RAM), set by variable                                                                                                  |
| Storage               | `gp3`, with storage autoscaling up to `max_allocated_storage`                                                                                      |
| High availability     | Multi-AZ; synchronous standby in another AZ with automatic failover                                                                                |
| Placement             | DB subnet group on the isolated data subnets, no public access                                                                                     |
| Network               | `rds-sg` accepts 5432 from `ec2-app-sg` only                                                                                                       |
| Encryption at rest    | Customer-managed KMS key (also used for Performance Insights)                                                                                      |
| Encryption in transit | TLS required (`rds.force_ssl = 1`)                                                                                                                 |
| Credentials           | `manage_master_user_password = true` (Secrets Manager managed), rotation every 30 days                                                             |
| Backups               | Automated, retention set by variable; backup window 03:00-04:00 UTC                                                                                |
| Maintenance           | Sunday 04:30-05:30 UTC                                                                                                                             |
| Protection            | `deletion_protection = true`; final snapshot required; tags copied to snapshots                                                                    |
| Observability         | Logs `postgresql` and `upgrade` exported to CloudWatch; Performance Insights on; Enhanced Monitoring every 60 seconds through a dedicated IAM role |

All writes go to the primary instance.

### 7.2 Read replica

A read replica (count set by `read_replica_count`) serves read-heavy queries and reporting. It uses the same instance
class, security group and KMS key, and has Performance Insights and Enhanced Monitoring enabled. Note the distinction:
the Multi-AZ standby is synchronous and exists only for failover, while the read replica is asynchronous and readable,
so replica lag must be monitored.

### 7.3 Secrets and credentials

- The database password is generated and stored in Secrets Manager, never in code or state files.
- Rotation runs every 30 days.
- The application reads the secret at startup using its instance role, through the Secrets Manager VPC endpoint.
- Parameter Store is not used for credentials (see 15).

## 8. Security and Encryption

### 8.1 Identity and access

- **No long-lived keys.** EC2 uses an instance role; GitHub Actions assumes a deployment role through an OIDC identity
  provider.
- **OIDC trust policy** is restricted to the specific repository and branches or environments allowed to deploy.
  Separate roles are used for `plan` (read-only) and `apply`.
- **Least privilege** applies to every policy; wildcards on resources are avoided.
- **Administration** is through SSM Session Manager only; there is no SSH inbound rule.

### 8.2 Encryption

| Data                                 | At rest                                    | In transit                            |
|:-------------------------------------|:-------------------------------------------|:--------------------------------------|
| Static site and ops buckets          | SSE-KMS (customer-managed key), versioning | TLS 1.2/1.3 via CloudFront            |
| Artifact bucket                      | SSE-KMS, versioning                        | HTTPS through the S3 Gateway endpoint |
| RDS, snapshots, Performance Insights | KMS customer-managed key                   | TLS enforced                          |
| Secrets Manager                      | KMS                                        | HTTPS through the interface endpoint  |
| CloudWatch log groups                | KMS                                        | AWS-internal TLS                      |
| SNS topics                           | KMS                                        | HTTPS                                 |
| DNSSEC signing                       | Asymmetric KMS key                         | n/a                                   |

Separate KMS keys are used per environment (dev, staging, prod), with automatic rotation enabled where the key type
supports it. Key policies grant the service principals that need them, for example CloudWatch to publish to the
encrypted SNS topic.

### 8.3 Audit

CloudTrail records all API activity (90-day retention in the event history, with a trail delivering to an encrypted S3
bucket for longer retention). VPC Flow Logs record network metadata.

## 9. Monitoring and Alerting

### 9.1 Severity model

| Severity | Meaning                                               | Response                 | Alarm prefix |
|:---------|:------------------------------------------------------|:-------------------------|:-------------|
| CRITICAL | Customer impact now, data-loss risk or security event | Immediate (page on-call) | `[CRITICAL]` |
| WARNING  | Degradation trend or shrinking headroom               | Same business day        | `[WARNING]`  |
| INFO     | Context only                                          | Dashboard only, no alarm | n/a          |

### 9.2 Logging

All log groups are KMS-encrypted, retained for 30 days in CloudWatch, and exported to S3 for long-term storage where
required. WAF logs use 7 days because of their volume.

| Source                                    | Log group                                       |
|:------------------------------------------|:------------------------------------------------|
| ALB access logs                           | `/aws/alb/spring-boot-app-alb`                  |
| Spring Boot application (structured JSON) | `/aws/ec2/spring-boot-backend-app-tier`         |
| RDS PostgreSQL                            | `/aws/rds/postgresql/spring-boot-database-tier` |
| WAF                                       | `aws-waf-logs-<prefix>`                         |
| VPC Flow Logs                             | Dedicated flow-log group                        |
| Instance bootstrap                        | `bootstrap`                                     |

### 9.3 Alarms

Alarms for CloudFront, WAF and ACM metrics are created in `us-east-1`, where those metrics are published.

**Edge**

| Alarm                                 | Metric and condition                                            | Severity           |
|:--------------------------------------|:----------------------------------------------------------------|:-------------------|
| `cf-5xx-warn`                         | `5xxErrorRate` > 1% (3 of 5 minutes)                            | WARNING            |
| `cf-5xx-crit`                         | `5xxErrorRate` > 5% (3 of 5)                                    | CRITICAL           |
| `cf-4xx-high`                         | `4xxErrorRate` > 15% (5 of 5)                                   | WARNING            |
| `cf-origin-latency`                   | `OriginLatency` p90 > 2000 ms (3 of 5)                          | WARNING            |
| `cf-requests-anomaly`                 | `Requests` above the 3-sigma anomaly band (3 of 3)              | WARNING            |
| `cf-cache-hit-low`                    | `CacheHitRate` below target for 15 min (cacheable content only) | WARNING            |
| `r53-api-health`                      | `HealthCheckStatus` < 1 (3 of 3, missing data = breaching)      | CRITICAL           |
| `acm-expiry-warn` / `acm-expiry-crit` | `DaysToExpiry` < 30 / < 7                                       | WARNING / CRITICAL |

**Application Load Balancer**

| Alarm               | Condition                                                          | Severity |
|:--------------------|:-------------------------------------------------------------------|:---------|
| High target 5xx     | `HTTPCode_Target_5XX_Count` above 1% of requests                   | CRITICAL |
| Low healthy hosts   | `HealthyHostCount` < 2                                             | CRITICAL |
| Unhealthy host      | `UnHealthyHostCount` > 0                                           | WARNING  |
| Slow responses      | `TargetResponseTime` p99 above the SLA threshold (for example 3 s) | WARNING  |
| Unusual traffic     | `RequestCount` anomaly (possible DDoS)                             | WARNING  |
| Connection problems | Target connection errors > 10/min; `RejectedConnectionCount` > 0   | WARNING  |

**Application tier**

Metric filters (namespace `Custom/<app>/AppTier`) turn log patterns into metrics:

| Filter                  | Pattern                                        | Alarm                     | Severity | Topic      |
|:------------------------|:-----------------------------------------------|:--------------------------|:---------|:-----------|
| `app-error-count`       | `{ $.level = "ERROR" }`                        | >= 10 per min (3 of 5)    | WARNING  | `app`      |
| `app-warn-count`        | `{ $.level = "WARN" }`                         | >= 100 per 5 min (2 of 3) | WARNING  | `app`      |
| `app-oom`               | `*OutOfMemoryError*` in message or stack trace | >= 1                      | CRITICAL | `app`      |
| `app-db-pool-exhausted` | `*Connection is not available*` (HikariCP)     | >= 5 per 5 min            | CRITICAL | `app`      |
| `app-startup-failure`   | `*APPLICATION FAILED TO START*`                | >= 1                      | CRITICAL | `app`      |
| `app-auth-failures`     | `{ $.event = "AUTH_FAILURE" }`                 | >= 20 per 5 min           | WARNING  | `security` |
| `bootstrap-failure`     | Bootstrap script failure strings               | >= 1                      | WARNING  | `asg`      |

Instance alarms: CPU > 80% for 5 minutes, memory > 90%, disk > 85%, and EC2 status-check failure. A **composite alarm**
(`app-critical`) combines `app-oom`, `app-db-pool-exhausted`, `app-startup-failure` and the ALB unhealthy-host alarm to
express overall application health. The CloudWatch Agent publishes memory, disk, network and process metrics at 1-minute
granularity.

**Database**

| Metric                         | Threshold                                                           | Severity           |
|:-------------------------------|:--------------------------------------------------------------------|:-------------------|
| `CPUUtilization`               | > 80% for 10 min (critical above 90%)                               | WARNING / CRITICAL |
| `FreeableMemory`               | < 10% of total                                                      | CRITICAL           |
| `FreeStorageSpace`             | < 15% of allocated (critical below 5 GB)                            | WARNING / CRITICAL |
| `DiskQueueDepth`               | > 20 sustained                                                      | WARNING            |
| `ReadLatency` / `WriteLatency` | > 20 ms sustained                                                   | WARNING            |
| `ReplicaLag`                   | > 5 s sustained                                                     | WARNING            |
| `DatabaseConnections`          | > 80% of `max_connections`                                          | WARNING            |
| Slow queries                   | `log_min_duration_statement` = 1000 ms, filtered from the log group | WARNING            |

### 9.4 Dashboards

One CloudWatch dashboard per layer, plus a combined operations view:

- **Edge:** requests, cache hit rate, origin latency, 4xx/5xx rate, bytes downloaded and uploaded.
- **ALB:** request count, target response time (p50/p99), healthy and unhealthy hosts, 5xx rate.
- **Application:** CPU, memory, disk, network, error and warning counts, latency percentiles, recent error log entries,
  NAT data transfer.
- **Database:** connections, latency, CPU, free storage, replica lag.

### 9.5 Notifications

KMS-encrypted SNS topics (`edge`, `app`, `asg`, `security`, `db`) deliver to email subscriptions. CRITICAL alarms can
additionally integrate with an on-call tool such as PagerDuty or Opsgenie if the team adopts one.

## 10. CI/CD and Terraform Operations

### 10.1 Delivery flow

`Commit and push → GitHub → GitHub Actions → OIDC role assumption → AWS`

| Pipeline       | Steps                                                                                                                              |
|:---------------|:-----------------------------------------------------------------------------------------------------------------------------------|
| Infrastructure | On pull request: `fmt`, `validate`, `plan` (plan posted to the PR). On merge: `apply`, with a manual approval gate for production. |
| Front end      | Build, sync to the website bucket, invalidate changed CloudFront paths.                                                            |
| Back end       | Build the JAR, upload it to the artifact bucket, update the launch template version, which triggers the instance refresh.          |

### 10.2 Terraform standards

- **Remote state:** S3 backend (versioned, KMS-encrypted, public access blocked) with a DynamoDB table for state
  locking.
- **Structure:** reusable modules (`network`, `edge`, `static-site`, `alb`, `compute`, `database`, `security`,
  `monitoring`) composed per environment; one state per environment.
- **Providers:** a default provider for the primary region and an aliased `us-east-1` provider for ACM, WAF and
  CloudFront-scoped resources.
- **Quality gates:** pinned provider and module versions, variables with validation, mandatory tagging (`Environment`,
  `Application`, `Tier`, `Owner`), and a policy or security scan in the pipeline.
- **Outputs:** each module exposes the outputs listed in section 13.

## 11. Backup and Recovery

| Asset           | Mechanism                                                                                                                |
|:----------------|:-------------------------------------------------------------------------------------------------------------------------|
| RDS             | Automated backups with point-in-time recovery, final snapshot on deletion, Multi-AZ failover                             |
| Backup vault    | AWS Backup plans write to an encrypted vault with lifecycle transition to cold storage (Glacier) for long-term retention |
| S3 buckets      | Versioning; lifecycle rules for logs and incomplete uploads                                                              |
| Terraform state | Versioned S3 bucket                                                                                                      |
| Compute         | Stateless and rebuilt from the launch template and the JAR in S3                                                         |

Recovery time and recovery point objectives must be defined and tested (see section 15).

## 12. Cost Optimization

| Control                                           | Effect                                                                    |
|:--------------------------------------------------|:--------------------------------------------------------------------------|
| Static site on S3 and CloudFront                  | No always-on compute for the front end                                    |
| Cache policies and long TTLs for assets           | Fewer origin requests and less data transfer                              |
| Auto Scaling with target tracking                 | Capacity follows demand                                                   |
| S3 lifecycle rules (Standard-IA, Glacier, expiry) | Lower storage cost for logs                                               |
| Gateway endpoint for S3                           | Avoids NAT data-processing charges for artifact downloads                 |
| Log retention limits and WAF log filtering        | Controls CloudWatch ingestion and storage                                 |
| Non-production environments                       | Single NAT Gateway and smaller instances where HA is not required         |
| AWS Budgets and Cost Anomaly Detection            | Month-to-date versus budget and forecast alerts, with an SNS notification |

Three NAT Gateways, Bot Control, Multi-AZ RDS and a read replica are the largest fixed costs and should be reviewed
against the budget before production sign-off.

## 13. Terraform Outputs

| Module     | Outputs                                                                                                                        |
|:-----------|:-------------------------------------------------------------------------------------------------------------------------------|
| Network    | VPC ID and CIDR, subnet IDs per tier, route table IDs, NAT Gateway IDs, security group IDs, endpoint IDs, DB subnet group name |
| Edge       | Hosted zone ID and nameservers, certificate ARN, CloudFront distribution ID and domain, WAF Web ACL ARN                        |
| Storage    | Website, ops and artifact bucket names and ARNs                                                                                |
| Compute    | ALB DNS name and ARN, target group ARN, launch template ID and version, Auto Scaling group name, instance profile ARN          |
| Database   | Primary endpoint, replica endpoints, secret ARN, KMS key ARN, SSM port-forwarding command for administrative access            |
| Monitoring | SNS topic ARNs, log group names, dashboard names                                                                               |
| Delivery   | OIDC provider ARN, deployment role ARNs, state bucket and lock table names                                                     |

## 14. Future Enhancements

- **ElastiCache** in front of the database for hot reads (shown in the architecture diagram but not specified in the
  original document).
- **Amazon EFS** shared storage for the app tier (also shown in the diagram only).
- **RDS Proxy** for connection pooling.
- **Multi-region** deployment with Route 53 geolocation routing and health-check failover, and cross-region backup copy.
- **Containers** (ECS or EKS with ECR) if the application moves away from JAR-on-EC2.

## 15. Reconciled Inconsistencies and Open Decisions

The source document contained conflicting statements. The table shows how each was resolved in this specification; items
marked **Confirm** need your decision.

| #  | Topic                                     | Source said                                                                     | Resolved as                                                                                                                                          |
|:---|:------------------------------------------|:--------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
| 1  | Database engine                           | MySQL in some sections, PostgreSQL in others                                    | PostgreSQL throughout                                                                                                                                |
| 2  | Target users and region                   | Users in Africa (use case) and Europe (overview); infrastructure in `us-east-1` | Africa as target audience, `us-east-1` as deployment region. **Confirm:** a nearer region such as `eu-west-1` or `af-south-1` may reduce API latency |
| 3  | Front-end hosting                         | Public S3 website endpoint, and private bucket with OAC                         | Private bucket behind CloudFront with OAC                                                                                                            |
| 4  | Credential storage                        | Parameter Store in some places, Secrets Manager in others                       | Secrets Manager only                                                                                                                                 |
| 5  | Web-tier servers and internal ALB         | Mentioned in flow and benefits, absent from the diagram                         | Removed; one internet-facing ALB in front of the app tier                                                                                            |
| 6  | Auto Scaling size                         | 2-6, 2-5, and "2 per AZ"                                                        | Min 2, max 6. **Confirm:** a minimum of 3 keeps one instance per AZ after an AZ failure                                                              |
| 7  | WAF rate limit                            | 20 and 2,000 requests per 5 minutes                                             | 2,000                                                                                                                                                |
| 8  | Data subnet CIDR                          | `18.0.33.0/24` for AZ-c                                                         | `18.0.23.0/24` (typo)                                                                                                                                |
| 9  | App-tier route to Internet Gateway        | Listed alongside NAT route                                                      | Removed; contradicts the private-subnet design                                                                                                       |
| 10 | Origin Access Control for ALB             | Listed as a task                                                                | Not supported for ALB origins; replaced with custom header and CloudFront prefix list                                                                |
| 11 | Replica terminology                       | "Read replica in sync (standby)"                                                | Multi-AZ standby (synchronous, failover) and read replica (asynchronous, readable) described separately                                              |
| 12 | Amazon ECR                                | Listed under CI/CD                                                              | Removed; the app is a JAR in S3                                                                                                                      |
| 13 | Lambda, API Gateway and throttling alarms | Copied wording in alarm lists                                                   | Removed; no such services in this design                                                                                                             |
| 14 | RDS Proxy output                          | `db_proxy_endpoint` output without a proxy                                      | Omitted; listed as a future enhancement                                                                                                              |
| 15 | Scaling claim                             | "Auto Scaling across all tiers"                                                 | Only the app tier uses an Auto Scaling group; the database scales through instance class, storage autoscaling and replicas                           |
| 16 | ACM region note                           | "\[TO CONFIRM\]"                                                                | CloudFront certificate in `us-east-1`; ALB uses a regional certificate                                                                               |
| 17 | Step versus target-tracking scaling       | Both described                                                                  | Target tracking only                                                                                                                                 |
| 18 | CORS policy                               | Wildcard origin                                                                 | Restricted to the application's domains                                                                                                              |

**Further open decisions**

- **VPC CIDR:** `18.0.0.0/16` is not a private (RFC 1918) range; confirm it is intentional or switch to a `10.x` range
  to avoid conflicts with public addresses.
- **Recovery objectives:** define RTO and RPO and schedule a restore test.
- **EFS and ElastiCache:** decide whether they are in scope for the first release.
- **Anonymous IP blocking:** the rule blocks VPN and proxy users, which may affect legitimate customers.
