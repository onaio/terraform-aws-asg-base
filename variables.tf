variable "env" {}
variable "project" {}
variable "project_id" {}
variable "deployment_type" {
  type        = string
  default     = "vm"
  description = "The deployment type the resources brought up by this module are part of."
}
variable "owner" {}
variable "end_date" {}
variable "vpc_id" {}
variable "alb_bucket_name" {}
variable "alb_ssl_policy" {}

variable "alb_idle_timeout" {
  default = 60
}

variable "alb_logs_user_identifiers" {
  type = list
}
variable "enable_alb_logs" {
  type    = bool
  default = true
}

variable "cookie_duration" {
  type        = number
  default     = 300
  description = "The time period, in seconds, during which requests from a client should be routed to the same target. After this time period expires, the load balancer-generated cookie is considered stale. The range is 1 second to 1 week (604800 seconds). The default value is 5 minutes (300 seconds)."
}

variable "enable_stickiness" {
  type        = bool
  default     = true
  description = "Boolean to enable / disable stickiness. Default is true"
}

variable "create_s3_bucket" {
  type        = bool
  default     = false
  description = "Whether to attempt to create the S3 bucket to be created in this module"
}
variable "data_bucket_name" {}
variable "data_bucket_region" {
  type = string
}

variable "iam_s3_user" {}

variable "create_certificate" {
  default = 0
}

variable "route53_zone_name" {}
variable "service_domain" {}
variable "iam_server_ssl_cert" {
  type        = string
  default     = ""
  description = "The IAM certificate name to attach to the load balancer. Set to a blank string if no certificate exists."
}

variable "service_https_port" {
  default = 443
}

variable "cnames" {
  type = list
}

variable "subnet_ids" {
  type = list
}

variable "health_check_path" {
  default = "/"
}

variable "http_health_check_port" {
  default = "traffic-port"
}

variable "http_health_check_protocol" {
  default = "HTTP"
  type    = string
}

variable "https_health_check_port" {
  default = "traffic-port"
}

variable "http_health_check_matcher" {
  default = "301"
}

variable "https_health_check_matcher" {
  default = "200"
}

variable "ignore_paths" {
  type    = list
  default = []
}

variable "deployed_app" {}

variable "redirect_paths" {
  default = []
  type    = list
}

variable "create_route53_records" {
  type        = bool
  default     = true
  description = "Whether to attempt to create the Route 53 records associated with this ASG"
}

variable "create_s3_user" {
  type        = bool
  default     = true
  description = "Whether to attempt to create the IAM user for accessing the S3 bucket to be created in this module"
}

variable "acm_certificate_domain" {
  type        = string
  default     = ""
  description = "The domain related to the ACM certificate to attach to the load balancer. Set to a blank string if no ACM certificate exists."
}

variable "asg_ssh_cidr_blocks" {
  type    = list
  default = ["0.0.0.0/0"]
}

variable "asg_http_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "asg_https_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "additional_ssl_certs" {
  type    = list
  default = []
}

variable "target_group_port" {
  type    = number
  default = 80
}

variable "target_group_protocol" {
  type    = string
  default = "HTTP"
}

variable "asg_instance_http_cidr_blocks" {
  type        = list
  default     = []
  description = "List of CIDR blocks to allow incoming HTTP traffic."
}

variable "asg_instance_https_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks to allow incoming HTTPS traffic."
}
