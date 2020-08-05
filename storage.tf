resource "aws_s3_bucket" "asg-logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = join("-", [var.alb_bucket_name, var.env])
  policy = data.aws_iam_policy_document.asg-logs[0].json

  tags = {
    Name            = join("-", [var.project_id, var.deployed_app, var.env])
    Group           = join("-", [var.project, var.env])
    OwnerList       = var.owner
    EnvironmentList = var.env
    EndDate         = var.end_date
    ProjectList     = var.project
    DeploymentType  = var.deployment_type
  }
}

provider "aws" {
  alias  = "s3provider"
  region = var.data_bucket_region
}

# When using s3 from a different region you need to use a
# specific provider for that region, give it an alias and in
# aws_s3_bucket "bucket_name" {
#     provider aws.s3provider
#     ...
# }
#
# This becomes relevant when you attempt to import a bucket
# from a different region.
# Reference: https://github.com/hashicorp/terraform/issues/13750
#
resource "aws_s3_bucket" "data" {
  count    = var.create_s3_bucket ? 1 : 0
  bucket   = var.data_bucket_name
  policy   = data.aws_iam_policy_document.data[count.index].json
  provider = aws.s3provider

  tags = {
    Name            = join("-", [var.project_id, var.deployed_app, var.env])
    Group           = join("-", [var.project, var.env])
    OwnerList       = var.owner
    EnvironmentList = var.env
    EndDate         = var.end_date
    ProjectList     = var.project
    DeploymentType  = var.deployment_type
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  cors_rule {
    allowed_headers = var.bucket_cors_allowed_headers
    allowed_methods = var.bucket_cors_allowed_methods
    allowed_origins = var.bucket_cors_allowed_origins
    expose_headers  = var.bucket_cors_expose_header
    max_age_seconds = var.bucket_cors_max_age_seconds
  }

}
