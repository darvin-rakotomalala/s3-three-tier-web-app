# 💰 FinOps Best Practices with Terraform

> **FinOps** brings financial accountability to cloud spending. Terraform, the most widely used Infrastructure as Code
> (IaC) tool, is uniquely positioned to put these practices directly into your infrastructure.

---

## 🏛️ The Three Pillars of FinOps

FinOps rests on three pillars. Terraform supports all of them through **infrastructure automation**, **policy
enforcement**, and **cost-aware resource management**.

| Pillar          | Goal                          | Focus                                        |
|-----------------|-------------------------------|----------------------------------------------|
| 🔍 **Inform**   | Visibility into spending      | Tagging, reports, budgets                    |
| ⚡ **Optimize** | Reduce waste                  | Right-sizing, Spot, shutdowns, lifecycle     |
| 🛡️ **Operate**  | Governance and accountability | Policies, cost estimation, anomaly detection |

### 🔍 Pillar 1: Inform — Cost Visibility

- **Consistent tagging for cost attribution**: enforce tags on every resource so costs can be traced to an owner.
- **Cost and Usage Reports (CUR)**: set up automated cost data collection.
- **Budget alerts at multiple levels**:
    - Organization budget
    - Per-team budgets using tags

### ⚡ Pillar 2: Optimize — Reduce Waste

- **Right-sizing infrastructure**: use variables to make resizing easy.
- **Spot Instances for non-critical workloads**: mix on-demand and Spot capacity.
- **Auto-shutdown for non-production**: schedule-based shutdown for dev and staging.
- **Storage lifecycle policies**: use S3 lifecycle rules to move data to cheaper storage tiers.

### 🛡️ Pillar 3: Operate — Governance

- **Cost policies**: use Terraform variable validation as cost guardrails.
- **Infracost integration**: add cost estimation to CI/CD.
- **Anomaly detection**: catch unexpected spend early.

---

## 🚀 FinOps Maturity Model

Adopt FinOps in stages. Each phase builds on the one before it.

```text
  🐛 Crawl  ───▶  🚶 Walk  ───▶  🏃 Run
  Visibility      Optimization    Governance
```

### 🐛 Crawl Phase — Basic Visibility

- [ ] Enable default tags
- [ ] Set up organization-level budgets
- [ ] Create CUR reports

### 🚶 Walk Phase — Add Optimization

- [ ] Implement right-sizing
- [ ] Deploy auto-shutdown schedules
- [ ] Add Infracost to CI/CD
- [ ] Set up per-team budgets

### 🏃 Run Phase — Full Governance

- [ ] Enforce cost policies with Sentinel/OPA
- [ ] Implement anomaly detection
- [ ] Create cost optimization dashboards
- [ ] Automate Reserved Instance / Savings Plan tracking

---

## 🧩 Reusable FinOps Module

Create a single Terraform module that implements all the FinOps basics, then reuse it across environments.

```hcl
# modules/finops/main.tf
module "finops" {
  source = "./modules/finops"

  organization_budget = 100000

  team_budgets = {
    platform    = 30000
    application = 25000
    data        = 35000
    sre         = 10000
  }

  alert_emails = ["finops@company.com"]
  enable_cur      = true
  enable_anomaly  = true
  enable_shutdown = true
  shutdown_tag    = "AutoShutdown"
}
```

---

## ✅ Best Practices Checklist

1. 🏷️ **Tag first.** Tagging is the foundation of FinOps, so implement it before anything else.
2. 🔎 **Use Infracost** in every CI/CD pipeline.
3. 💵 **Create budgets** at the organization, account, and team levels.
4. 📏 **Right-size** instances based on actual utilization data.
5. 📉 **Match pricing to workload:** Savings Plans for predictable workloads, Spot Instances for fault-tolerant and
   flexible ones.
6. 🌙 **Automate shutdown** of non-production resources.
7. 🗓️ **Review costs monthly** with engineering and finance teams.
8. 📊 **Track FinOps metrics:**
    - Cost per customer
    - Waste percentage
    - Savings achieved

---

## 📝 Summary

Terraform is a powerful enabler for FinOps. By codifying cost visibility, optimization, and governance into your
infrastructure configurations, you make these practices **consistent, auditable, and automated**.

| Phase        | What to do                                                |
|--------------|-----------------------------------------------------------|
| 🐛 **Crawl** | Start with tagging and budgets                            |
| 🚶 **Walk**  | Add optimization and Infracost                            |
| 🏃 **Run**   | Build full governance with policies and anomaly detection |

Combining Terraform with FinOps principles creates a sustainable approach to cloud financial management.
