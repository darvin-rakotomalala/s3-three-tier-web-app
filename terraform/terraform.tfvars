# ─── Adjust for your environment ────────────────────────────────────
primary_region      = "us-east-1"
environment         = "dev"
project_name        = "three-tier"
team_name           = "training"
cost_center         = "engineering"
compliance          = "internal"
github_org          = "darvin-rakotomalala"
github_repo         = "s3-three-tier-web-app"
bucket_name         = "ce-dev-terraform-state-69127"
email_subscriptions = ["darvintojo@gmail.com"]

# ─── Frontend
domain_name  = "cloudwithdarvin.com"
source_files = "../ec2-web-app-frontend"

# ─── Backend
vpc_cidr                        = "18.0.0.0/16"
availability_zones              = ["us-east-1a", "us-east-1b", "us-east-1c"]
single_nat_gateway              = false
instance_type                   = "t3.medium"
instance_type_overrides         = ["t3.medium", "t3a.medium", "t3.large"]
app_port                        = 8080
db_port                         = 5432
jar_bucket_name                 = "ce-dev-ec2-web-app-backend-jar-bucket-69127"
jar_local_path                  = "ec2-web-app-backend.jar"
jar_object_key                  = "ec2-web-app-backend.jar"
api_subdomain                   = "api"
origin_subdomain                = "origin"
db_engine_version               = "16.4"
db_instance_class               = "db.r5.large"
db_allocated_storage            = 100
db_max_allocated_storage        = 500
db_name                         = "threetierdb"
db_username                     = "app_admin"
db_multi_az                     = true
db_backup_retention_days        = 7
log_retention_days              = 30
cpu_threshold_percent           = 80
connection_threshold_percent    = 80
monthly_budget_ec2_usd          = 200
monthly_budget_rds_usd          = 300
monthly_budget_cloudfront_usd   = 100
cloudfront_price_class          = "PriceClass_100"
health_check_path               = "/health"
enable_deletion_protection      = false
asg_min_size                    = 2
asg_max_size                    = 6
asg_desired_capacity            = 2
on_demand_base_capacity         = 1
on_demand_percentage_above_base = 25
