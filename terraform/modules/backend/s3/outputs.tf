############################################
# S3 OUTPUTS
############################################

output "jar_artifacts_bucket_name" {
  description = "ID of the S3 bucket storing the Spring Boot JAR artifact"
  value       = aws_s3_bucket.jar_artifacts.id
}

output "jar_artifacts_bucket_arn" {
  description = "ARN of the S3 bucket storing the Spring Boot JAR artifact"
  value       = aws_s3_bucket.jar_artifacts.arn
}

output "app_jar_object_id" {
  description = "Reference this in the ASG's depends_on so instances launch after the JAR exists"
  value       = aws_s3_object.app_jar.id
}