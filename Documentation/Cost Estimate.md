# AWS Cost Estimate: Production-Grade Three-Tier Web Application (Terraform)

## 1. Key sizing values read from the plan

| Variable                      | Value                                                                                                                                         |
|-------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Availability Zones            | 3 (`us-east-1a/b/c`)                                                                                                                          |
| `single_nat_gateway`          | `false` → **3 NAT Gateways**                                                                                                                  |
| EC2 instance type / overrides | `t3.medium` / `t3.medium`, `t3a.medium`, `t3.large`                                                                                           |
| ASG min / desired / max       | 2 / 2 / 6                                                                                                                                     |
| On-Demand base / % above base | 1 / 25% (rest Spot)                                                                                                                           |
| EBS root volume               | 30 GiB gp3 (KMS-encrypted), detailed monitoring on                                                                                            |
| RDS                           | PostgreSQL 16.4, `db.r5.large`, **Multi-AZ**, gp3 100 GiB (autoscale to 500), 7-day backups, Performance Insights, Enhanced Monitoring (60 s) |
| CloudFront                    | 2 distributions (frontend + API), `PriceClass_100`                                                                                            |
| Log retention                 | 30 days                                                                                                                                       |

## 2. Monthly cost estimate (baseline: 2 instances, low traffic)

| #  | Service                                                   | Terraform resources                                                         | Sizing / assumption                                                     | Est. monthly (USD) |
|----|-----------------------------------------------------------|-----------------------------------------------------------------------------|-------------------------------------------------------------------------|-------------------:|
| 1  | **RDS PostgreSQL**: instance                              | `aws_db_instance`                                                           | db.r5.large Multi-AZ, ~$0.50/h                                          |             365.00 |
| 2  | RDS: storage                                              | same                                                                        | 100 GiB gp3 Multi-AZ, ~$0.23/GiB                                        |              23.00 |
| 3  | **NAT Gateways**: hourly                                  | `aws_nat_gateway` ×3                                                        | 3 × $0.045/h                                                            |              98.55 |
| 4  | NAT Gateways: data processing                             | same                                                                        | ~100 GB total at $0.045/GB                                              |               4.50 |
| 5  | **VPC Interface Endpoints**                               | `aws_vpc_endpoint` ×4 types (ssm, ssmmessages, ec2messages, secretsmanager) | 4 endpoints × 3 AZ ENIs × $0.01/h                                       |              87.60 |
| 6  | **EC2 On-Demand**                                         | `aws_autoscaling_group`                                                     | 1 × t3.medium, $0.0416/h                                                |              30.37 |
| 7  | EC2 Spot                                                  | same                                                                        | 1 × t3.medium Spot, ~$0.015/h                                           |              10.95 |
| 8  | EC2 detailed monitoring                                   | `aws_launch_template`                                                       | 2 instances × 7 metrics × $0.30                                         |               4.20 |
| 9  | EBS gp3                                                   | launch template                                                             | 2 × 30 GiB × $0.08                                                      |               4.80 |
| 10 | **ALB**                                                   | `aws_lb`                                                                    | $0.0225/h + ~1 LCU ($0.008/h)                                           |              22.27 |
| 11 | Public IPv4 addresses                                     | `aws_eip` ×3 + ALB (3 AZs)                                                  | 6 × $0.005/h                                                            |              21.90 |
| 12 | **WAF**                                                   | `aws_wafv2_web_acl`                                                         | 1 ACL ($5) + 12 rules ($12) + Bot Control ($10) + ~1M requests (~$1.60) |              28.60 |
| 13 | **CloudFront** (2 distributions)                          | `aws_cloudfront_distribution` ×2                                            | ~50 GB egress + ~2M requests (before free tier)                         |               8.00 |
| 14 | CloudWatch alarms                                         | `aws_cloudwatch_metric_alarm` ×28, composite ×1                             | 28 × $0.10 + $0.50                                                      |               3.30 |
| 15 | CloudWatch dashboards                                     | `aws_cloudwatch_dashboard` ×4                                               | 3 free, 1 × $3                                                          |               3.00 |
| 16 | CloudWatch Logs + metric filters                          | 5 log groups, flow logs, 3 metric filters                                   | ~15 GB ingest × $0.50 + storage + 3 custom metrics                      |               9.00 |
| 17 | **KMS**                                                   | `aws_kms_key` ×8 (incl. Route 53 DNSSEC)                                    | 8 × $1 + requests                                                       |              10.00 |
| 18 | Secrets Manager                                           | `aws_secretsmanager_secret` ×1                                              | $0.40 + API calls                                                       |               0.50 |
| 19 | S3 (3 buckets)                                            | `aws_s3_bucket` ×3                                                          | website + logs + JAR, < 10 GB                                           |               1.00 |
| 20 | Route 53                                                  | `aws_route53_record` ×7, DNSSEC                                             | Hosted zone already exists (data source); standard queries only         |               0.50 |
| 21 | RDS Enhanced Monitoring logs                              | via CloudWatch Logs                                                         | 60 s granularity                                                        |               3.00 |
| 22 | SNS, SSM Parameter, ACM, IAM, SG, NACL, IGW, Budgets, VPC | various                                                                     | Free or negligible                                                      |               0.00 |
|    |                                                           |                                                                             | **Estimated total (baseline)**                                          |  **≈ 740 / month** |

*Annualised: ≈ $8,900.*

## 3. Scenarios

| Scenario         | Change                                                                                                                             |                            Est. monthly (USD) |
|------------------|------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------:|
| **Baseline**     | 2 instances (1 On-Demand + 1 Spot), low traffic                                                                                    |                                     **≈ 740** |
| **Peak load**    | ASG at max 6 (2 On-Demand + 4 Spot t3.large/medium) → ~+$75 EC2/EBS/monitoring; higher ALB LCU, NAT and CloudFront traffic → ~+$40 |                                     **≈ 855** |
| **Budget check** | Your own budgets: EC2 $200 + RDS $300 + CloudFront $100                                                                            | RDS alone (~$388) **exceeds** its $300 budget |

> The `monthly_budget_rds_usd = 300` budget will alert on a Multi-AZ `db.r5.large` (about $388/month with storage).
> Consider raising it or downsizing.

## 4. Top cost drivers

| Rank | Item                     | Share of baseline |
|------|--------------------------|------------------:|
| 1    | RDS (instance + storage) |              ~52% |
| 2    | NAT Gateways (3 AZs)     |              ~14% |
| 3    | VPC Interface Endpoints  |              ~12% |
| 4    | EC2 + EBS + monitoring   |               ~7% |
| 5    | WAF + ALB + public IPv4  |              ~10% |

## 5. Savings opportunities

| Option                                               | Change                                                    |    Est. saving / month |
|------------------------------------------------------|-----------------------------------------------------------|-----------------------:|
| Single NAT Gateway (non-prod)                        | `single_nat_gateway = true`                               |   ~ $70 (incl. 2 EIPs) |
| Right-size RDS for dev                               | `db.t4g.large` or `db.r6g.large` instead of `db.r5.large` |          ~ $90 to $150 |
| Single-AZ RDS for dev                                | `db_multi_az = false`                                     |                 ~ $190 |
| Interface endpoints in 1 to 2 AZs only               | Fewer ENIs                                                |           ~ $29 to $58 |
| Drop Bot Control rule group (if not needed)          | WAF                                                       |                 ~ $11+ |
| Reserved Instances / Savings Plan (1-yr, no upfront) | RDS and EC2                                               |   ~ 30% on those lines |
| Schedule dev environment off-hours                   | Stop RDS, scale ASG to 0                                  | up to ~ 60% on compute |

A dev profile combining single NAT, single-AZ RDS on a smaller class, and endpoints in one AZ lands at roughly
**$300 to $380/month**.

---

# AWS Cost Optimization Plan: Three-Tier Web Application (Terraform)

**Baseline:** ≈ **$740/month** (us-east-1, 2 EC2 instances, low traffic), from `Cost Estimate.md`.
Savings are estimates in USD/month using On-Demand list prices; verify with the AWS Pricing Calculator.

## 1. Where the money goes

| Rank | Cost driver                              | Baseline (USD) | Share |
|-----:|------------------------------------------|---------------:|------:|
|    1 | RDS `db.r5.large` Multi-AZ + 100 GiB gp3 |         388.00 |   52% |
|    2 | NAT Gateways ×3 (+ data)                 |         103.05 |   14% |
|    3 | VPC interface endpoints (4 × 3 AZs)      |          87.60 |   12% |
|    4 | EC2 + EBS + detailed monitoring          |          50.32 |    7% |
|    5 | WAF + ALB + public IPv4                  |          72.77 |   10% |
|    6 | CloudWatch, KMS, S3, other               |            ~38 |    5% |

## 2. Recommendations (highest impact first)

|  # | Area                                 | Terraform change                                                                                                                                    |                     Est. saving / month | Effort | Risk / trade-off                                                                        |
|---:|--------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------:|--------|-----------------------------------------------------------------------------------------|
|  1 | **RDS: Multi-AZ off in dev**         | `db_multi_az = false`                                                                                                                               |                                **~194** | Low    | No automatic failover; keep `true` for prod                                             |
|  2 | **RDS: right-size**                  | `db_instance_class = "db.t4g.large"` (dev) or `db.r6g.large` (prod)                                                                                 |                              ~90 to 180 | Low    | Check CPU/memory in CloudWatch first; burstable CPU credits on t4g; maintenance restart |
|  3 | **RDS: Reserved Instance** (prod)    | 1-yr, no upfront, matching class and Multi-AZ                                                                                                       |                 ~115 (≈30% of instance) | Low    | 1-year commitment; buy after right-sizing                                               |
|  4 | **NAT: single gateway** (non-prod)   | `single_nat_gateway = true`                                                                                                                         |               ~73 (2 gateways + 2 EIPs) | Low    | Loses AZ-independent egress; NACL/route logic already handles the flag                  |
|  5 | **NAT: remove if unused**            | Drop NAT and rely on S3 gateway + SSM/Secrets endpoints                                                                                             |                                    ~103 | Medium | Only if instances need no other internet egress (OS updates, third-party APIs)          |
|  6 | **Interface endpoints in fewer AZs** | Pass 1 to 2 `app_subnet_ids` to `aws_vpc_endpoint`                                                                                                  |               ~29 (2 AZs) to ~58 (1 AZ) | Low    | Cross-AZ data charge ($0.01/GB) and less resilience for SSM access                      |
|  7 | **Endpoints vs NAT**                 | Keep only the Secrets Manager endpoint (or none) and let SSM traffic use NAT                                                                        |                               up to ~66 | Medium | Weaker "no internet path" security posture; do not combine with #5                      |
|  8 | **WAF: trim rules**                  | Remove Bot Control (`AWSManagedRulesBotControlRuleSet`) if not required; review overlapping managed groups (each rule is $1)                        |                               ~11 to 15 | Low    | Less bot protection; Bot Control also bills per request                                 |
|  9 | **EC2: Graviton**                    | `instance_type = "t4g.medium"` and overrides `t4g.medium`, `t4g.large` (needs arm64 AMI)                                                            |                  ~5 to 8 (≈19% cheaper) | Medium | Java JAR is architecture-neutral; the AMI data source and user_data need arm64          |
| 10 | **EC2: more Spot**                   | `on_demand_percentage_above_base = 0` (keep base 1)                                                                                                 |        ~5 to 25 (grows with fleet size) | Low    | Spot interruptions; the ASG already uses mixed instances                                |
| 11 | **EC2: Compute Savings Plan**        | 1-yr, commit to steady On-Demand base only                                                                                                          |                                ~8 to 10 | Low    | Commitment; only worthwhile if base fleet stays steady                                  |
| 12 | **EC2 detailed monitoring off**      | Launch template `monitoring { enabled = false }`                                                                                                    |                                      ~4 | Low    | 5-minute metrics slow alarm and scaling reaction; keep in prod                          |
| 13 | **ALB / public IPv4**                | Use 2 AZs for ALB subnets                                                                                                                           |                                      ~4 | Medium | Lower AZ spread; conflicts with the 3-AZ spec                                           |
| 14 | **CloudWatch Logs**                  | VPC flow logs: send to S3 or capture `REJECT` only; shorten `log_retention_days` in dev; filter noisy app logs                                      |                                 ~3 to 6 | Low    | Less retained detail for investigations                                                 |
| 15 | **CloudWatch dashboards**            | Keep 3 (first 3 are free), merge the 4th                                                                                                            |                                      ~3 | Low    | Fewer views                                                                             |
| 16 | **KMS key consolidation**            | Merge low-sensitivity keys (e.g. CloudWatch, SSM, JAR) into one; enable S3 Bucket Keys                                                              |                                 ~3 to 5 | Medium | Wider blast radius per key; compliance may require separation                           |
| 17 | **Schedule non-prod**                | Scheduled actions: ASG min/desired 0 nights and weekends; stop RDS outside hours (stopped RDS auto-restarts after 7 days; confirm Multi-AZ support) | up to ~60% of EC2 and RDS instance cost | Medium | Environment unavailable off-hours                                                       |
| 18 | **S3 lifecycle**                     | Expire old log and JAR versions (`aws_s3_bucket_lifecycle_configuration` already exists; tighten days, add noncurrent-version expiry)               |                                      ~1 | Low    | Shorter history                                                                         |
| 19 | **CloudFront free tier**             | Keep both distributions in one account to use the 1 TB / 10M request free tier; keep `PriceClass_100`                                               |                                 ~0 to 8 | None   | Already set                                                                             |
| 20 | **Budgets**                          | Align `monthly_budget_rds_usd` (currently 300) with the chosen RDS size; add a total-account budget                                                 |                                     n/a | Low    | RDS at ~$388 would alert immediately                                                    |

## 3. Optimization profiles

| Profile                                 | What is applied                                               | Est. monthly (USD) |   Saving vs baseline |
|-----------------------------------------|---------------------------------------------------------------|-------------------:|---------------------:|
| **Baseline (as planned)**               | Current variables                                             |              ≈ 740 |                  n/a |
| **Quick wins** (no architecture change) | #8, #12 (dev only), #14, #15                                  |       ≈ 715 to 720 |      ~ 20 to 25 (3%) |
| **Production, HA kept**                 | Multi-AZ + 3 NAT kept; #2 (`db.r6g.large`), #3, #8, #9, #11   |       ≈ 560 to 600 | ~ 140 to 180 (≈ 22%) |
| **Dev / sandbox**                       | #1, #2 (`db.t4g.large`), #4, #6 (1 AZ), #8, #9, #12, #14, #15 |       ≈ 300 to 320 |        ~ 420 (≈ 57%) |
| **Dev + scheduled**                     | Dev profile plus #17 (≈ 50 h/week uptime)                     |       ≈ 200 to 240 |        ~ 500 (≈ 68%) |

## 4. Suggested `terraform.tfvars` for a dev environment

```hcl
single_nat_gateway              = true
db_multi_az                     = false
db_instance_class               = "db.t4g.large"
db_backup_retention_days        = 3
log_retention_days              = 14
instance_type                   = "t4g.medium"
instance_type_overrides = ["t4g.medium", "t4g.large"]
on_demand_base_capacity         = 1
on_demand_percentage_above_base = 0
asg_min_size                    = 1
asg_desired_capacity            = 1
asg_max_size                    = 3
enable_deletion_protection      = false
monthly_budget_rds_usd          = 150
```

Changes outside variables (edit the modules): fewer endpoint subnets (#6), remove Bot Control (#8), disable detailed
monitoring (#12), flow log filter (#14), scheduled scaling actions (#17).

## 5. Keep for production (do not cut)

| Item                                                                  | Why                                                     |
|-----------------------------------------------------------------------|---------------------------------------------------------|
| RDS Multi-AZ                                                          | Automatic failover; the main HA requirement of the spec |
| One NAT Gateway per AZ                                                | AZ-independent egress                                   |
| WAF managed rules (Common, KnownBadInputs, IP reputation, rate limit) | Core protection for a public endpoint                   |
| KMS encryption, flow logs, 30-day log retention                       | Compliance and audit posture                            |
| Interface endpoints for SSM and Secrets Manager                       | No bastion, no public IPs, private access               |

## 6. Cost governance

| Action                                 | Detail                                                                                                        |
|----------------------------------------|---------------------------------------------------------------------------------------------------------------|
| Cost allocation tags                   | `Project`, `Environment`, `CostCenter` are already in `common_tags`; activate them in Billing                 |
| AWS Budgets                            | You have EC2, RDS and CloudFront budgets; add a total budget with 50/80/100% alerts to the existing SNS topic |
| Cost Anomaly Detection                 | Free; add a monitor on the `Project` tag                                                                      |
| Compute Optimizer / CloudWatch metrics | Review RDS CPU and memory and EC2 utilization after 2 weeks before right-sizing                               |
| Infracost in CI                        | Run `infracost breakdown` on pull requests for this Terraform to catch cost changes before apply              |
