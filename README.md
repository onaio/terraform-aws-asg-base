# Auto-scaling Base Terraform module

This module configures the aws security group, aws route53 cnames, aws alb, aws alb target groups, aws alb listeners for an auto-scaling setup. It has `target_group_arns` and `security_groups` as outputs.

## Usage Example

```hcl

module "rapidpro" {
  source = "../../modules/asg-base"

  env                          = "${var.env}"
  project                      = "${var.project}"
  project_id                   = "${var.project_id}"
  owner                        = "${var.owner}"
  end_date                     = "${var.end_date}"
  alb_bucket_name              = "${var.alb_bucket_name}"
  alb_logs_user_identifiers    = "${var.alb_logs_user_identifiers}"
  alb_ssl_policy               = "${var.alb_ssl_policy}"
  route53_zone_name            = "${var.route53_zone_name}"
  service_domain               = "${var.service_domain}"
  iam_server_ssl_cert          = "${var.iam_server_ssl_cert}"
  cnames                       = "${var.cnames}"
  data_bucket_name             = "${var.data_bucket_name}"
  data_bucket_user_identifiers = "${var.data_bucket_user_identifiers}"
  vpc_id                       = "${module.rapidpro-vpc.main_vpc_id}"
  subnet_ids                   = "${module.rapidpro-vpc.subnet_ids}"
}
```
