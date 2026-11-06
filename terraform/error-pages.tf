#########################################################
## UPLOAD ERROR PAGES
#########################################################

resource "aws_s3_object" "error_404" {
  bucket       = module.front_s3.frontend_s3_bucket_cloudfront_ops_id
  key          = "error-pages/404.html"
  source       = "${path.module}/error-pages/404.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/error-pages/404.html")

  lifecycle {
    ignore_changes = [
      etag,
      source,
    ]
  }
}

resource "aws_s3_object" "error_500" {
  bucket       = module.front_s3.frontend_s3_bucket_cloudfront_ops_id
  key          = "error-pages/500.html"
  source       = "${path.module}/error-pages/500.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/error-pages/500.html")
  lifecycle {
    ignore_changes = [
      etag,
      source,
    ]
  }
}
