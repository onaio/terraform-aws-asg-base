data "aws_route53_zone" "primary" {
  for_each = var.route53_zone_names
  name     = each.value
}

data "aws_security_group" "default" {
  vpc_id = var.vpc_id
  name   = "default"
}

data "aws_subnet_ids" "main" {
  vpc_id = var.vpc_id
}

data "aws_subnet" "main" {
  for_each = data.aws_subnet_ids.main.ids
  id       = each.value
}

locals {
  vpc_subnet_cidr_blocks = [for subnet in data.aws_subnet.main : subnet.cidr_block]
}

data "aws_iam_server_certificate" "asg" {
  count  = length(var.iam_server_ssl_cert) > 0 ? 1 - var.create_certificate : 0
  name   = var.iam_server_ssl_cert
  latest = true
}

data "aws_acm_certificate" "asg" {
  count       = length(var.acm_certificate_domain) > 0 ? 1 - var.create_certificate : 0
  domain      = var.acm_certificate_domain
  most_recent = true
}

data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "asg-logs" {
  count = var.enable_alb_logs ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      format("arn:aws:s3:::%s-%s/AWSLogs/*", var.alb_bucket_name, var.env),
    ]
  }
}

resource "aws_iam_user" "s3-user" {
  count = var.create_s3_user && var.create_s3_bucket ? 1 : 0
  name  = var.iam_s3_user
}

data "aws_iam_user" "s3-user" {
  count     = ! var.create_s3_user && var.create_s3_bucket ? 1 : 0
  user_name = var.iam_s3_user
}

data "aws_iam_policy_document" "data" {
  count = var.create_s3_bucket ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.create_s3_user ? aws_iam_user.s3-user[count.index].arn : data.aws_iam_user.s3-user[0].arn]
    }

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      format("arn:aws:s3:::%s/*", var.data_bucket_name),
    ]
  }

  statement {

    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.create_s3_user ? aws_iam_user.s3-user[count.index].arn : data.aws_iam_user.s3-user[0].arn]
    }

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      format("arn:aws:s3:::%s", var.data_bucket_name),
    ]
  }
}
