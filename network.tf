resource "aws_security_group" "asg" {
  name        = join("-", [var.project_id, var.deployed_app, var.env])
  description = "Allow http https ssh inbound, all outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.asg_http_cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.asg_https_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_security_group" "asg_instance" {
  name_prefix = join("-", [var.project_id, var.deployed_app, "instances", var.env])
  description = "Allow http https ssh inbound, all outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.asg_ssh_cidr_blocks
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat(local.vpc_subnet_cidr_blocks, var.asg_instance_http_cidr_blocks)
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat(local.vpc_subnet_cidr_blocks, var.asg_instance_https_cidr_blocks)
  }

  ingress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_route53_record" "asg" {
  count   = var.create_route53_records ? length(var.service_domains) : 0
  zone_id = data.aws_route53_zone.primary[var.service_domains[count.index]].zone_id
  name    = var.service_domains[count.index]
  type    = "A"

  alias {
    name                   = aws_alb.asg.dns_name
    zone_id                = aws_alb.asg.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "asg-cnames" {
  count   = var.create_route53_records ? length(var.cnames) : 0
  zone_id = data.aws_route53_zone.primary[element(var.cnames, count.index)].zone_id
  name    = element(var.cnames, count.index)
  type    = "CNAME"
  ttl     = "300"
  records = [aws_route53_record.asg[0].name]
}

resource "aws_alb" "asg" {
  name            = join("-", [var.project_id, var.deployed_app, var.env])
  internal        = false
  security_groups = [data.aws_security_group.default.id, aws_security_group.asg.id]
  subnets         = var.subnet_ids
  depends_on      = [aws_acm_certificate.cert]

  enable_deletion_protection = false
  idle_timeout               = var.alb_idle_timeout

  access_logs {
    bucket  = var.enable_alb_logs ? aws_s3_bucket.asg-logs[0].bucket : ""
    enabled = var.enable_alb_logs
  }

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

resource "aws_alb_target_group" "http" {
  name                 = substr(join("-", [var.project_id, var.deployed_app, "http", var.env]), 0, 32)
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  deregistration_delay = 60

  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.cookie_duration
    enabled         = var.enable_stickiness
  }

  health_check {
    path     = var.health_check_path
    matcher  = var.http_health_check_matcher
    protocol = var.http_health_check_protocol
    port     = var.http_health_check_port
  }

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

resource "aws_alb_target_group" "https" {
  # I am not sure we need to have this any more because we have https
  #  termination at the load balancer and it only needs http access
  count = 0

  name                 = join("-", [var.project_id, "https", var.env])
  port                 = 443
  protocol             = "HTTPS"
  vpc_id               = var.vpc_id
  deregistration_delay = 60

  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.cookie_duration
    enabled         = var.enable_stickiness
  }

  health_check {
    path     = var.health_check_path
    matcher  = var.https_health_check_matcher
    protocol = "HTTPS"
    port     = var.https_health_check_port
  }

  tags = {
    Name            = join("-", [var.project_id, var.env])
    Group           = join("-", [var.project, var.env])
    OwnerList       = var.owner
    EnvironmentList = var.env
    EndDate         = var.end_date
    ProjectList     = var.project
    DeploymentType  = var.deployment_type
  }
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.asg.arn
  port              = 80
  protocol          = "HTTP"
  depends_on        = [aws_alb.asg]

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_acm_certificate" "cert" {
  count                     = var.create_certificate
  domain_name               = var.service_domains[0]
  validation_method         = "DNS"
  subject_alternative_names = length(var.service_domains) > 1 ? concat(slice(var.service_domains, 1, length(var.service_domains)), var.cnames) : var.cnames

  tags = {
    Name            = join("-", [var.project_id, var.deployed_app, var.env])
    Group           = join("-", [var.project, var.env])
    OwnerList       = var.owner
    EnvironmentList = var.env
    EndDate         = var.end_date
    ProjectList     = var.project
    DeploymentType  = var.deployment_type
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count      = var.create_certificate == 1 ? length(var.cnames) + length(var.service_domains) : 0
  depends_on = [aws_acm_certificate.cert]
  name       = lookup(element(tolist(aws_acm_certificate.cert[0].domain_validation_options[*]), count.index), "resource_record_name")
  type       = lookup(element(tolist(aws_acm_certificate.cert[0].domain_validation_options[*]), count.index), "resource_record_type")
  zone_id    = data.aws_route53_zone.primary[lookup(element(tolist(aws_acm_certificate.cert[0].domain_validation_options[*]), count.index), "domain_name")].id
  records    = [lookup(element(tolist(aws_acm_certificate.cert[0].domain_validation_options[*]), count.index), "resource_record_value")]
  ttl        = 60
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = var.create_certificate
  certificate_arn         = aws_acm_certificate.cert[count.index].arn
  validation_record_fqdns = aws_route53_record.cert_validation.*.fqdn

  timeouts {
    create = "1h"
  }
}

resource "aws_alb_listener" "https_listener_1" {
  count             = var.create_certificate
  load_balancer_arn = aws_alb.asg.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = aws_acm_certificate_validation.cert[count.index].certificate_arn
  depends_on        = [aws_alb.asg]

  default_action {
    target_group_arn = aws_alb_target_group.http.arn
    type             = "forward"
  }
}

resource "aws_alb_listener" "https_listener" {
  count             = 1 - var.create_certificate
  load_balancer_arn = aws_alb.asg.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = length(var.iam_server_ssl_cert) > 0 ? data.aws_iam_server_certificate.asg[count.index].arn : data.aws_acm_certificate.asg[count.index].arn
  depends_on        = [aws_alb.asg]

  default_action {
    target_group_arn = aws_alb_target_group.http.arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "http-ignore-rules" {
  count        = length(var.ignore_paths)
  listener_arn = aws_alb_listener.http_listener.arn
  priority     = count.index + 100

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  condition {
    path_pattern {
      values = [element(var.ignore_paths, count.index)]
    }
  }
}

resource "aws_alb_listener_rule" "https-ignore-rules" {
  count        = length(var.ignore_paths)
  listener_arn = element(concat(aws_alb_listener.https_listener.*.arn, aws_alb_listener.https_listener_1.*.arn), 0)
  priority     = count.index + 100

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  condition {
    path_pattern {
      values = [element(var.ignore_paths, count.index)]
    }
  }
}

resource "aws_alb_listener_rule" "redirect_paths" {
  count = length(var.redirect_paths)

  listener_arn = element(concat(aws_alb_listener.https_listener.*.arn, aws_alb_listener.https_listener_1.*.arn), 0)

  action {
    type = "redirect"

    redirect {
      host        = element(var.redirect_paths, count.index).host
      path        = element(var.redirect_paths, count.index).path
      status_code = element(var.redirect_paths, count.index).status_code
    }
  }

  dynamic "condition" {
    for_each = length(lookup(element(var.redirect_paths, count.index), "path_pattern_conditions", [])) > 0 ? toset(["path_pattern_conditions"]) : toset([])

    content {
      path_pattern {
        values = element(var.redirect_paths, count.index).path_pattern_conditions
      }
    }
  }

  dynamic "condition" {
    for_each = length(lookup(element(var.redirect_paths, count.index), "host_header_conditions", [])) > 0 ? toset(["host_header_conditions"]) : toset([])

    content {
      host_header {
        values = element(var.redirect_paths, count.index).host_header_conditions
      }
    }
  }
}

resource "aws_alb_listener_rule" "host_based_routing" {
  count = length(var.routing_hosts)

  listener_arn = element(concat(aws_alb_listener.https_listener.*.arn, aws_alb_listener.https_listener_1.*.arn), 0)

  action {
    type             = "forward"
    target_group_arn = element(var.routing_hosts, count.index).target_group_arn
  }

  condition {
    host_header {
      values = element(var.routing_hosts, count.index).host_headers
    }
  }
}

data "aws_acm_certificate" "extra" {
  count    = length(var.additional_ssl_certs)
  domain   = element(var.additional_ssl_certs, count.index)
  statuses = ["ISSUED"]
}

resource "aws_lb_listener_certificate" "https_certificate" {
  count           = length(var.additional_ssl_certs)
  listener_arn    = element(concat(aws_alb_listener.https_listener.*.arn, aws_alb_listener.https_listener_1.*.arn), 0)
  certificate_arn = element(data.aws_acm_certificate.extra.*.arn, count.index)
}

resource "aws_cloudwatch_metric_alarm" "requests_5xx_count" {
  alarm_name                = "${aws_alb.asg.name}-requests-5xx-count"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.cloudwatch_alarm_requests_5xx_count_evaluation_periods
  metric_name               = "HTTPCode_Target_5XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = var.cloudwatch_alarm_requests_5xx_count_period
  statistic                 = "Sum"
  threshold                 = var.cloudwatch_alarm_requests_5xx_threshold
  alarm_actions             = var.cloudwatch_alarm_actions
  ok_actions                = var.cloudwatch_ok_actions
  insufficient_data_actions = var.cloudwatch_insufficient_data_actions
  treat_missing_data        = "notBreaching"

  dimensions = {
    LoadBalancer = aws_alb.asg.arn_suffix
    TargetGroup  = aws_alb_target_group.http.arn_suffix
  }
}
