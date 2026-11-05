## Production-Grade Three-Tier Web Application on AWS (Terraform)

A secure, highly available and auto-scaling three-tier web application on AWS, defined entirely as code with Terraform
and deployed through GitHub Actions using keyless (OIDC) authentication.

- **Presentation tier:** static frontend on Amazon S3, delivered through CloudFront with WAF protection
- **Application tier:** Java Spring Boot REST API on EC2 Auto Scaling instances in private subnets, behind an
  Application Load Balancer
- **Data tier:** Amazon RDS for PostgreSQL (Multi-AZ) in isolated database subnets

### Deploy

```bash
$ cd s3-three-tier-web-app/terraform
$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="terraform.tfvars" -auto-approve
```

### Verification and Testing

After deployment, the site was live at `https://cloudwithdarvin.com/` with a secure connection confirmed by the browser.

- website_url = "https://cloudwithdarvin.com"
- www_website_url = "https://www.cloudwithdarvin.com"

### Cleanup

***

To destroy all resources, run ```terraform destroy -var-file="terraform.tfvars" -auto-approve```
