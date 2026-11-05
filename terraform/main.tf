#########################################################
# IAM
#########################################################

module "iam" {
  source                    = "./modules/iam"
  current_account_id        = data.aws_caller_identity.current.account_id
  naming_prefix             = local.naming_prefix
  common_tags               = local.common_tags
  github_org                = var.github_org
  github_repo               = var.github_repo
  current_partition         = data.aws_partition.current.partition
  db_master_user_secret_arn = module.secrets.db_credentials_secret_arn
  ec2_linux_kms_key_arn     = module.kms.ec2_linux_kms_key_arn
  jar_artifacts_bucket_arn  = module.s3.jar_artifacts_bucket_arn
  kms_key_cloudwatch_arn    = module.kms.kms_cloudwatch_key_arn
  kms_key_jar_artifacts_arn = module.kms.kms_key_jar_artifacts_arn
  kms_key_secrets_arn       = module.kms.kms_secrets_key_arn
  log_group_app_tier_arn    = module.cloudwatch.ec2_access_log_group_arn
  primary_region            = var.primary_region
  region_current_name       = data.aws_region.current.region
  ssm_parameter_arn         = module.ssm_parameter.ssm_parameter_arn
}

#########################################################
# ROUTE 53
#########################################################

module "route53" {
  source                                 = "./modules/route53"
  current_account_id                     = data.aws_caller_identity.current.account_id
  naming_prefix                          = local.naming_prefix
  common_tags                            = local.common_tags
  frontend_cf_website_domain_name        = module.cloudfront.frontend_cf_website_domain_name
  frontend_cf_website_hosted_zone_id     = module.cloudfront.frontend_cf_website_hosted_zone_id
  data_zone_id                           = data.aws_route53_zone.existing.zone_id
  domain_name                            = var.domain_name
  data_aws_route53_zone_existing_zone_id = data.aws_route53_zone.existing.zone_id
  alb_dns_name                           = module.alb.alb_dns_name
  alb_zone_id                            = module.alb.alb_zone_id
  api_subdomain                          = var.api_subdomain
  cloudfront_domain_name                 = module.cloudfront.backend_cloudfront_domain_name
  cloudfront_hosted_zone_id              = module.cloudfront.backend_cloudfront_hosted_zone_id
  origin_subdomain                       = var.origin_subdomain
  route53_zone_id                        = data.aws_route53_zone.existing.zone_id
}

#########################################################
# ACM
#########################################################

module "acm" {
  source = "./modules/acm"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  naming_prefix    = local.naming_prefix
  common_tags      = local.common_tags
  domain_name      = var.domain_name
  api_subdomain    = var.api_subdomain
  origin_subdomain = var.origin_subdomain
  route53_zone_id  = data.aws_route53_zone.existing.zone_id
}

#########################################################
# KMS
#########################################################

module "kms" {
  source                     = "./modules/kms"
  current_account_id         = data.aws_caller_identity.current.account_id
  naming_prefix              = local.naming_prefix
  common_tags                = local.common_tags
  current_partition          = data.aws_partition.current.partition
  ec2_app_role_arn           = module.iam.ec2_app_role_arn
  kms_cloudwatch_policy_json = module.iam.kms_cloudwatch_policy_json
  log_group_arn              = local.log_group_arn
  primary_region             = var.primary_region
  principal_logs_arn         = local.principal_logs_arn
  principal_root_arn         = local.principal_root_arn
}

#########################################################
# S3 WEBSITE AND CLOUDFRONT LOGGING
#########################################################

module "s3" {
  source                       = "./modules/s3"
  naming_prefix                = local.naming_prefix
  common_tags                  = local.common_tags
  frontend_s3_key_arn          = module.kms.frontend_s3_key_arn
  ec2_app_role_arn             = module.iam.ec2_app_role_arn
  environment                  = var.environment
  jar_bucket_name              = var.jar_bucket_name
  jar_local_path               = var.jar_local_path
  jar_object_key               = var.jar_object_key
  kms_key_jar_artifacts_arn    = module.kms.kms_key_jar_artifacts_arn
  current_account_id           = data.aws_caller_identity.current.account_id
  elb_service_account_main_arn = data.aws_elb_service_account.main.arn
}

#########################################################
# CLOUDFRONT
#########################################################

module "cloudfront" {
  source                                     = "./modules/cloudfront"
  naming_prefix                              = local.naming_prefix
  common_tags                                = local.common_tags
  frontend_acm_certificate_arn               = module.acm.frontend_acm_certificate_arn
  cloudfront_ops_bucket                      = module.s3.cloudfront_ops_bucket
  cloudfront_ops_bucket_domain_name          = module.s3.cloudfront_ops_bucket_domain_name
  cloudfront_ops_bucket_regional_domain_name = module.s3.cloudfront_ops_bucket_regional_domain_name
  data_cf_caching_optimized_id               = data.aws_cloudfront_cache_policy.caching_optimized.id
  data_cf_cors_s3_origin_id                  = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
  data_cf_security_headers_id                = data.aws_cloudfront_response_headers_policy.security_headers.id
  domain_name                                = var.domain_name
  s3_bucket_cloudfront_ops_arn               = module.s3.s3_bucket_cloudfront_ops_arn
  s3_bucket_cloudfront_ops_id                = module.s3.s3_bucket_cloudfront_ops_id
  s3_bucket_website_arn                      = module.s3.s3_bucket_website_arn
  s3_bucket_website_id                       = module.s3.s3_bucket_website_id
  website_bucket                             = module.s3.website_bucket
  website_bucket_regional_domain_name        = module.s3.website_bucket_regional_domain_name
  waf_web_acl_arn                            = module.waf.frontend_cf_waf_acl_arn
  backend_acm_cloudfront_certificate_arn     = module.acm.backend_acm_cloudfront_certificate_arn
  backend_acm_origin_certificate_arn         = module.acm.backend_acm_origin_certificate_arn
  backend_api_subdomain                      = var.api_subdomain
  backend_cloudfront_origin_secret_result    = module.alb.cloudfront_origin_secret_result
  backend_cloudfront_price_class             = var.cloudfront_price_class
  backend_origin_record_name                 = module.route53.backend_origin_record_name
}

#########################################################
# WAF
#########################################################

module "waf" {
  source        = "./modules/waf"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
}

#########################################################
# CLOUDWATCH
#########################################################

module "cloudwatch" {
  source = "./modules/cloudwatch"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  naming_prefix                 = local.naming_prefix
  common_tags                   = local.common_tags
  frontend_cf_distribution_id   = module.cloudfront.frontend_distribution_id
  frontend_sns_topic_arn        = module.sns.frontend_sns_topic_arn
  alb_arn_suffix                = module.alb.alb_arn_suffix
  app_autoscaling_group_name    = module.autoscaling-group.app_autoscaling_group_name
  backend_cf_distribution_id    = module.cloudfront.backend_cloudfront_distribution_id
  connection_threshold_percent  = var.connection_threshold_percent
  cpu_threshold_percent         = var.cpu_threshold_percent
  current_account_id            = data.aws_caller_identity.current.account_id
  current_partition             = data.aws_partition.current.partition
  db_instance_class             = var.db_instance_class
  db_instance_main_identifier   = module.rds.db_instance_main_identifier
  ec2_linux_kms_key_arn         = module.kms.ec2_linux_kms_key_arn
  kms_cloudwatch_key_arn        = module.kms.kms_cloudwatch_key_arn
  log_retention_days            = var.log_retention_days
  monthly_budget_cloudfront_usd = var.monthly_budget_cloudfront_usd
  monthly_budget_ec2_usd        = var.monthly_budget_ec2_usd
  monthly_budget_rds_usd        = var.monthly_budget_rds_usd
  primary_region                = var.primary_region
  sns_alerts_topic_arn          = module.sns.backend_sns_alerts_topic_arn
  target_group_arn_suffix       = module.alb.target_group_arn_suffix
}

#########################################################
# SNS
#########################################################

module "sns" {
  source                = "./modules/sns"
  naming_prefix         = local.naming_prefix
  common_tags           = local.common_tags
  email_subscriptions   = var.email_subscriptions
  current_account_id    = data.aws_caller_identity.current.account_id
  kms_cloudwatch_key_id = module.kms.kms_cloudwatch_key_id
}

#########################################################
## UPLOAD HTML FILES TO S3 BUCKET
#########################################################
locals {
  mime_types = {
    "html"  = "text/html"
    "css"   = "text/css"
    "js"    = "application/javascript"
    "json"  = "application/json"
    "pdf"   = "application/pdf"
    "webp"  = "image/webp"
    "png"   = "image/png"
    "jpg"   = "image/jpeg"
    "jpeg"  = "image/jpeg"
    "svg"   = "image/svg+xml"
    "ico"   = "image/x-icon"
    "woff"  = "font/woff"
    "woff2" = "font/woff2"
    "ttf"   = "font/ttf"
    "txt"   = "text/plain"
  }
}

resource "aws_s3_object" "provision_source_files" {
  bucket   = module.s3.s3_bucket_website_id
  for_each = fileset("${var.source_files}/", "**/*.*")
  key      = each.value
  source   = "${var.source_files}/${each.value}"
  # Extract the file extension and look up the correct MIME type
  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
  etag         = filemd5("${var.source_files}/${each.value}")
  # cache_control = startswith(each.value, "assets/") ? "public, max-age=31536000, immutable" : "no-cache"

  lifecycle {
    ignore_changes = [
      etag,
      source,
      source_hash,
      content_type,
      cache_control,
      metadata,
      tags,
      tags_all,
    ]
  }
}

# ─── Backend

#########################################################
## VPC
#########################################################

module "vpc" {
  source             = "./modules/vpc"
  common_tags        = local.common_tags
  naming_prefix      = local.naming_prefix
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway
  vpc_cidr           = var.vpc_cidr
}

#########################################################
## VPC FLOW LOGS
#########################################################

module "flow-logs" {
  source                 = "./modules/flow-logs"
  common_tags            = local.common_tags
  naming_prefix          = local.naming_prefix
  kms_cloudwatch_key_arn = module.kms.kms_cloudwatch_key_arn
  vpc_id                 = module.vpc.vpc_id
  log_retention_days     = var.log_retention_days
}

#########################################################
## NACLs
#########################################################

module "nacls" {
  source             = "./modules/nacls"
  common_tags        = local.common_tags
  naming_prefix      = local.naming_prefix
  app_subnet_cidrs   = module.vpc.app_subnet_cidrs
  app_subnet_ids     = module.vpc.app_subnet_ids
  availability_zones = var.availability_zones
  db_subnet_ids      = module.vpc.db_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  vpc_id             = module.vpc.vpc_id
  app_port           = var.app_port
  db_port            = var.db_port
  single_nat_gateway = var.single_nat_gateway
  vpc_cidr           = var.vpc_cidr
}

#########################################################
## SECURITY GROUPS
#########################################################

module "sg" {
  source        = "./modules/sg"
  common_tags   = local.common_tags
  naming_prefix = local.naming_prefix
  vpc_id        = module.vpc.vpc_id
  app_port      = var.app_port
  db_port       = var.db_port
}

#########################################################
## VPC ENDPOINT
#########################################################

module "endpoint" {
  source                          = "./modules/endpoint"
  common_tags                     = local.common_tags
  naming_prefix                   = local.naming_prefix
  app_route_table_ids             = module.vpc.app_route_table_ids
  app_subnet_ids                  = module.vpc.app_subnet_ids
  current_account_id              = data.aws_caller_identity.current.account_id
  db_master_user_secret_arn       = module.secrets.db_credentials_secret_arn
  jar_artifacts_bucket_arn        = module.s3.jar_artifacts_bucket_arn
  ssm_endpoints_security_group_id = module.sg.ssm_endpoints_security_group_id
  vpc_id                          = module.vpc.vpc_id
  primary_region                  = var.primary_region
}


#########################################################
## ALB
#########################################################

module "alb" {
  source                       = "./modules/alb"
  naming_prefix                = local.naming_prefix
  common_tags                  = local.common_tags
  backend_acm_certificate_arn  = module.acm.backend_acm_origin_certificate_arn
  alb_security_group_id        = module.sg.alb_security_group_id
  public_subnet_ids            = module.vpc.public_subnet_ids
  vpc_id                       = module.vpc.vpc_id
  app_port                     = var.app_port
  enable_deletion_protection   = var.enable_deletion_protection
  health_check_path            = var.health_check_path
  alb_logs_s3_bucket_id        = module.s3.alb_logs_s3_bucket_id
  alb_logs_s3_bucket_policy_id = module.s3.alb_logs_s3_bucket_policy_id
}

#########################################################
## ASG
#########################################################

module "autoscaling-group" {
  source                          = "./modules/autoscaling-group"
  naming_prefix                   = local.naming_prefix
  common_tags                     = local.common_tags
  alb_target_group_arn            = module.alb.alb_target_group_arn
  alb_target_group_resource_label = module.alb.alb_target_group_resource_label
  app_launch_template_id          = module.launch-template.app_launch_template_id
  app_subnet_ids                  = module.vpc.app_subnet_ids
  launch_template_latest_version  = module.launch-template.launch_template_latest_version
  asg_desired_capacity            = var.asg_desired_capacity
  asg_max_size                    = var.asg_max_size
  asg_min_size                    = var.asg_min_size
  instance_type_overrides         = var.instance_type_overrides
  on_demand_base_capacity         = var.on_demand_base_capacity
  on_demand_percentage_above_base = var.on_demand_percentage_above_base
}

#########################################################
## LAUNCH TEMPLATE
#########################################################

module "launch-template" {
  source                      = "./modules/launch-template"
  naming_prefix               = local.naming_prefix
  common_tags                 = local.common_tags
  app_security_group_id       = module.sg.app_security_group_id
  ebs_kms_key_arn             = module.kms.ebs_kms_key_arn
  environment                 = var.environment
  instance_profile_arn        = module.iam.ec2_app_instance_profile_arn
  instance_type               = var.instance_type
  jar_artifacts_bucket_name   = module.s3.jar_artifacts_bucket_name
  ssm_parameter_name          = module.ssm_parameter.ssm_parameter_name
  ec2_linux_kms_alias_arn     = module.kms.ec2_linux_kms_alias_arn
  ec2_linux_kms_key_policy_id = module.kms.ec2_linux_kms_key_policy_id
}

#########################################################
# SYSTEMS MANAGER PARAMETER
#########################################################

module "ssm_parameter" {
  source                   = "./modules/ssm_parameter"
  naming_prefix            = local.naming_prefix
  common_tags              = local.common_tags
  ec2_linux_kms_key_id     = module.kms.ec2_linux_kms_key_id
  ec2_linux_log_group_name = module.cloudwatch.ec2_linux_log_group_name
}

#########################################################
## RDS
#########################################################

module "rds" {
  source                           = "./modules/rds"
  naming_prefix                    = local.naming_prefix
  common_tags                      = local.common_tags
  app_instance_ids                 = module.autoscaling-group.ec2_instance_ids[0]
  db_subnet_group_name             = module.vpc.db_subnet_group_name
  environment                      = var.environment
  kms_rds_key_arn                  = module.kms.kms_rds_key_arn
  primary_region                   = var.primary_region
  random_password_db_master_result = module.secrets.random_password_db_master_result
  rds_enhanced_monitoring_role_arn = module.iam.rds_enhanced_monitoring_role_arn
  rds_security_group_id            = module.sg.rds_security_group_id
  db_allocated_storage             = var.db_allocated_storage
  db_backup_retention_days         = var.db_backup_retention_days
  db_engine_version                = var.db_engine_version
  db_instance_class                = var.db_instance_class
  db_max_allocated_storage         = var.db_max_allocated_storage
  db_multi_az                      = var.db_multi_az
  db_name                          = var.db_name
  db_port                          = var.db_port
  db_username                      = var.db_username
}

#########################################################
## SECRETS MANAGER
#########################################################

module "secrets" {
  source              = "./modules/secrets"
  naming_prefix       = local.naming_prefix
  common_tags         = local.common_tags
  db_name             = var.db_name
  db_username         = var.db_username
  kms_secrets_key_arn = module.kms.kms_secrets_key_arn
  rds_address         = module.rds.rds_address
  rds_port            = module.rds.rds_port
}
