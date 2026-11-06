###---- FRONTEND PROVISIONING------------------------------------

/*
#########################################################
# IAM
#########################################################

module "front_iam" {
  source             = "./modules/frontend/iam"
  current_account_id = data.aws_caller_identity.current.account_id
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  github_org         = var.github_org
  github_repo        = var.github_repo
}
*/

#########################################################
# ROUTE 53
#########################################################

module "front_route53" {
  source                                 = "./modules/frontend/route53"
  current_account_id                     = data.aws_caller_identity.current.account_id
  naming_prefix                          = local.naming_prefix
  common_tags                            = local.common_tags
  cf_website_domain_name                 = module.front_cloudfront.cf_website_domain_name
  cf_website_hosted_zone_id              = module.front_cloudfront.cf_website_hosted_zone_id
  data_zone_id                           = data.aws_route53_zone.existing.zone_id
  domain_name                            = var.domain_name
  data_aws_route53_zone_existing_zone_id = data.aws_route53_zone.existing.zone_id
}

#########################################################
# ACM
#########################################################

module "front_acm" {
  source        = "./modules/frontend/acm"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
  data_zone_id  = data.aws_route53_zone.existing.zone_id
  domain_name   = var.domain_name
}

#########################################################
# KMS
#########################################################

module "front_kms" {
  source             = "./modules/frontend/kms"
  current_account_id = data.aws_caller_identity.current.account_id
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
}

#########################################################
# S3 WEBSITE AND CLOUDFRONT LOGGING
#########################################################

module "front_s3" {
  source        = "./modules/frontend/s3"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
  s3_key_arn    = module.front_kms.s3_key_arn
}

#########################################################
# CLOUDFRONT
#########################################################

module "front_cloudfront" {
  source                                     = "./modules/frontend/cloudfront"
  naming_prefix                              = local.naming_prefix
  common_tags                                = local.common_tags
  acm_certificate_arn                        = module.front_acm.acm_certificate_arn
  cloudfront_ops_bucket                      = module.front_s3.cloudfront_ops_bucket
  cloudfront_ops_bucket_domain_name          = module.front_s3.cloudfront_ops_bucket_domain_name
  cloudfront_ops_bucket_regional_domain_name = module.front_s3.cloudfront_ops_bucket_regional_domain_name
  data_cf_caching_optimized_id               = data.aws_cloudfront_cache_policy.caching_optimized.id
  data_cf_cors_s3_origin_id                  = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
  data_cf_security_headers_id                = data.aws_cloudfront_response_headers_policy.security_headers.id
  domain_name                                = var.domain_name
  s3_bucket_cloudfront_ops_arn               = module.front_s3.s3_bucket_cloudfront_ops_arn
  s3_bucket_cloudfront_ops_id                = module.front_s3.frontend_s3_bucket_cloudfront_ops_id
  s3_bucket_website_arn                      = module.front_s3.s3_bucket_website_arn
  s3_bucket_website_id                       = module.front_s3.frontend_s3_bucket_website_id
  website_bucket                             = module.front_s3.website_bucket
  website_bucket_regional_domain_name        = module.front_s3.website_bucket_regional_domain_name
  waf_web_acl_arn                            = module.front_waf.cf_waf_acl_arn
}

#########################################################
# WAF
#########################################################

module "front_waf" {
  source        = "./modules/frontend/waf"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
}

#########################################################
# CLOUDWATCH
#########################################################

module "front_cloudwatch" {
  source             = "./modules/frontend/cloudwatch"
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  cf_distribution_id = module.front_cloudfront.distribution_id
  sns_topic_arn      = [module.front_sns.sns_topic_arn]
}

#########################################################
# SNS
#########################################################

module "front_sns" {
  source              = "./modules/frontend/sns"
  naming_prefix       = local.naming_prefix
  common_tags         = local.common_tags
  email_subscriptions = var.email_subscriptions
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
  bucket       = module.front_s3.frontend_s3_bucket_website_id
  for_each     = fileset("${var.source_files}/", "**/*.*")
  key          = each.value
  source       = "${var.source_files}/${each.value}"
  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
  etag         = filemd5("${var.source_files}/${each.value}")

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

###---- BACKEND PROVISIONING------------------------------------

#########################################################
## VPC
#########################################################

module "back_vpc" {
  source             = "./modules/backend/vpc"
  common_tags        = local.common_tags
  naming_prefix      = local.naming_prefix
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway
  vpc_cidr           = var.vpc_cidr
}

#########################################################
## VPC FLOW LOGS
#########################################################

module "back_flow-logs" {
  source                 = "./modules/backend/flow-logs"
  common_tags            = local.common_tags
  naming_prefix          = local.naming_prefix
  kms_cloudwatch_key_arn = module.back_kms.kms_cloudwatch_key_arn
  vpc_id                 = module.back_vpc.vpc_id
  log_retention_days     = var.log_retention_days
}

#########################################################
## NACLs
#########################################################

module "back_nacls" {
  source             = "./modules/backend/nacls"
  common_tags        = local.common_tags
  naming_prefix      = local.naming_prefix
  app_subnet_cidrs   = module.back_vpc.app_subnet_cidrs
  app_subnet_ids     = module.back_vpc.app_subnet_ids
  availability_zones = var.availability_zones
  db_subnet_ids      = module.back_vpc.db_subnet_ids
  public_subnet_ids  = module.back_vpc.public_subnet_ids
  vpc_id             = module.back_vpc.vpc_id
  app_port           = var.app_port
  db_port            = var.db_port
  single_nat_gateway = var.single_nat_gateway
  vpc_cidr           = var.vpc_cidr
}

#########################################################
## SECURITY GROUPS
#########################################################

module "back_sg" {
  source        = "./modules/backend/sg"
  common_tags   = local.common_tags
  naming_prefix = local.naming_prefix
  vpc_id        = module.back_vpc.vpc_id
  app_port      = var.app_port
  db_port       = var.db_port
}

#########################################################
## VPC ENDPOINT
#########################################################

module "back_endpoint" {
  source                          = "./modules/backend/endpoint"
  common_tags                     = local.common_tags
  naming_prefix                   = local.naming_prefix
  app_route_table_ids             = module.back_vpc.app_route_table_ids
  app_subnet_ids                  = module.back_vpc.app_subnet_ids
  current_account_id              = data.aws_caller_identity.current.account_id
  db_master_user_secret_arn       = module.back_secrets.db_credentials_secret_arn
  jar_artifacts_bucket_arn        = module.back_s3.jar_artifacts_bucket_arn
  ssm_endpoints_security_group_id = module.back_sg.ssm_endpoints_security_group_id
  vpc_id                          = module.back_vpc.vpc_id
  primary_region                  = var.primary_region
}

#########################################################
## IAM
#########################################################

module "back_iam" {
  source                    = "./modules/backend/iam"
  current_account_id        = data.aws_caller_identity.current.account_id
  naming_prefix             = local.naming_prefix
  common_tags               = local.common_tags
  github_org                = var.github_org
  github_repo               = var.github_repo
  current_partition         = data.aws_partition.current.partition
  db_master_user_secret_arn = module.back_secrets.db_credentials_secret_arn
  jar_artifacts_bucket_arn  = module.back_s3.jar_artifacts_bucket_arn
  kms_key_cloudwatch_arn    = module.back_kms.kms_cloudwatch_key_arn
  kms_key_jar_artifacts_arn = module.back_kms.kms_key_jar_artifacts_arn
  kms_key_secrets_arn       = module.back_kms.kms_secrets_key_arn
  log_group_app_tier_arn    = module.back_cloudwatch.ec2_access_log_group_arn
  primary_region            = var.primary_region
}

#########################################################
## ACM
#########################################################

module "back_acm" {
  source = "./modules/backend/acm"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  naming_prefix    = local.naming_prefix
  common_tags      = local.common_tags
  route53_zone_id  = data.aws_route53_zone.main.zone_id
  api_subdomain    = var.api_subdomain
  domain_name      = var.domain_name
  origin_subdomain = var.origin_subdomain
}

#########################################################
## ALB
#########################################################

module "back_alb" {
  source                     = "./modules/backend/alb"
  naming_prefix              = local.naming_prefix
  common_tags                = local.common_tags
  acm_certificate_arn        = module.back_acm.acm_origin_certificate_arn
  alb_security_group_id      = module.back_sg.alb_security_group_id
  public_subnet_ids          = module.back_vpc.public_subnet_ids
  vpc_id                     = module.back_vpc.vpc_id
  app_port                   = var.app_port
  db_port                    = var.db_port
  enable_deletion_protection = var.enable_deletion_protection
  health_check_path          = var.health_check_path
}

#########################################################
## CLOUDFRONT
#########################################################

module "back_cloudfront" {
  source                          = "./modules/backend/cloudfront"
  naming_prefix                   = local.naming_prefix
  common_tags                     = local.common_tags
  acm_cloudfront_certificate_arn  = module.back_acm.acm_cloudfront_certificate_arn
  acm_origin_certificate_arn      = module.back_acm.acm_origin_certificate_arn
  cloudfront_origin_secret_result = module.back_alb.cloudfront_origin_secret_result
  origin_record_name              = module.back_route53.origin_record_name
  api_subdomain                   = var.api_subdomain
  cloudfront_price_class          = var.cloudfront_price_class
  domain_name                     = var.domain_name
}

#########################################################
## ROUTE 53
#########################################################

module "back_route53" {
  source                    = "./modules/backend/route53"
  naming_prefix             = local.naming_prefix
  common_tags               = local.common_tags
  alb_dns_name              = module.back_alb.alb_dns_name
  alb_zone_id               = module.back_alb.alb_zone_id
  cloudfront_domain_name    = module.back_cloudfront.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.back_cloudfront.cloudfront_hosted_zone_id
  route53_zone_id           = data.aws_route53_zone.main.zone_id
  api_subdomain             = var.api_subdomain
  domain_name               = var.domain_name
  origin_subdomain          = var.origin_subdomain
}

#########################################################
## ASG
#########################################################

module "back_autoscaling-group" {
  source                          = "./modules/backend/autoscaling-group"
  naming_prefix                   = local.naming_prefix
  common_tags                     = local.common_tags
  alb_target_group_arn            = module.back_alb.alb_target_group_arn
  alb_target_group_resource_label = module.back_alb.alb_target_group_resource_label
  app_launch_template_id          = module.back_launch-template.app_launch_template_id
  app_subnet_ids                  = module.back_vpc.app_subnet_ids
  launch_template_latest_version  = module.back_launch-template.launch_template_latest_version
  asg_desired_capacity            = var.asg_desired_capacity
  asg_max_size                    = var.asg_max_size
  asg_min_size                    = var.asg_min_size
  instance_type_overrides         = var.instance_type_overrides
  on_demand_base_capacity         = var.on_demand_base_capacity
  on_demand_percentage_above_base = var.on_demand_percentage_above_base
  lb_target_group_app_arn         = module.back_alb.lb_target_group_app_arn
}

#########################################################
## LAUNCH TEMPLATE
#########################################################

module "back_launch-template" {
  source                     = "./modules/backend/launch-template"
  naming_prefix              = local.naming_prefix
  common_tags                = local.common_tags
  app_security_group_id      = module.back_sg.app_security_group_id
  ebs_kms_key_arn            = module.back_kms.ebs_kms_key_arn
  environment                = var.environment
  instance_profile_arn       = module.back_iam.ec2_app_instance_profile_arn
  instance_type              = var.instance_type
  app_autoscaling_group_name = module.back_autoscaling-group.app_autoscaling_group_name
  jar_artifacts_bucket_name  = module.back_s3.jar_artifacts_bucket_name
}

#########################################################
## RDS
#########################################################

module "back_rds" {
  source                           = "./modules/backend/rds"
  naming_prefix                    = local.naming_prefix
  common_tags                      = local.common_tags
  app_instance_ids                 = module.back_autoscaling-group.ec2_instance_ids[0]
  db_subnet_group_name             = module.back_vpc.db_subnet_group_name
  environment                      = var.environment
  kms_rds_key_arn                  = module.back_kms.kms_rds_key_arn
  primary_region                   = var.primary_region
  random_password_db_master_result = module.back_secrets.random_password_db_master_result
  rds_enhanced_monitoring_role_arn = module.back_iam.rds_enhanced_monitoring_role_arn
  rds_security_group_id            = module.back_sg.rds_security_group_id
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
## KMS
#########################################################

module "back_kms" {
  source                     = "./modules/backend/kms"
  naming_prefix              = local.naming_prefix
  common_tags                = local.common_tags
  current_account_id         = data.aws_caller_identity.current.account_id
  current_partition          = data.aws_partition.current.partition
  ec2_app_role_arn           = module.back_iam.ec2_app_role_arn
  kms_cloudwatch_policy_json = module.back_iam.kms_cloudwatch_policy_json
  primary_region             = var.primary_region
}

#########################################################
## SECRETS MANAGER
#########################################################

module "back_secrets" {
  source              = "./modules/backend/secrets"
  naming_prefix       = local.naming_prefix
  common_tags         = local.common_tags
  db_name             = var.db_name
  db_username         = var.db_username
  kms_secrets_key_arn = module.back_kms.kms_secrets_key_arn
  rds_address         = module.back_rds.rds_address
  rds_port            = module.back_rds.rds_port
}

#########################################################
## SNS
#########################################################

module "back_sns" {
  source                = "./modules/backend/sns"
  naming_prefix         = local.naming_prefix
  common_tags           = local.common_tags
  current_account_id    = data.aws_caller_identity.current.account_id
  kms_cloudwatch_key_id = module.back_kms.kms_cloudwatch_key_id
  primary_region        = var.primary_region
  alert_emails          = var.alert_emails
}

#########################################################
## S3
#########################################################

module "back_s3" {
  source                    = "./modules/backend/s3"
  naming_prefix             = local.naming_prefix
  common_tags               = local.common_tags
  ec2_app_role_arn          = module.back_iam.ec2_app_role_arn
  environment               = var.environment
  kms_key_jar_artifacts_arn = module.back_kms.kms_key_jar_artifacts_arn
  jar_bucket_name           = var.jar_bucket_name
  jar_local_path            = var.jar_local_path
  jar_object_key            = var.jar_object_key
}

#########################################################
## CLOUDWATCH
#########################################################

module "back_cloudwatch" {
  source = "./modules/backend/cloudwatch"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  primary_region                = var.primary_region
  naming_prefix                 = local.naming_prefix
  common_tags                   = local.common_tags
  alb_arn_suffix                = module.back_alb.alb_arn_suffix
  app_autoscaling_group_name    = module.back_autoscaling-group.app_autoscaling_group_name
  cloudfront_distribution_id    = module.back_cloudfront.cloudfront_distribution_id
  current_account_id            = data.aws_caller_identity.current.account_id
  current_partition             = data.aws_partition.current.partition
  db_instance_class             = var.db_instance_class
  db_instance_main_identifier   = module.back_rds.db_instance_main_identifier
  kms_cloudwatch_key_arn        = module.back_kms.kms_cloudwatch_key_arn
  sns_alerts_topic_arn          = module.back_sns.sns_alerts_topic_arn
  target_group_arn_suffix       = module.back_alb.target_group_arn_suffix
  connection_threshold_percent  = var.connection_threshold_percent
  cpu_threshold_percent         = var.cpu_threshold_percent
  log_retention_days            = var.log_retention_days
  monthly_budget_cloudfront_usd = var.monthly_budget_cloudfront_usd
  monthly_budget_ec2_usd        = var.monthly_budget_ec2_usd
  monthly_budget_rds_usd        = var.monthly_budget_rds_usd
}
