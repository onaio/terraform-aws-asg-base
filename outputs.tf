output "target_group_arns" {
  value = concat(list(aws_alb_target_group.http.arn), aws_alb_target_group.https.*.arn)
}

output "security_groups" {
  value = [aws_security_group.asg_instance.id]
}

output "asg_https_listeners_arn" {
  value = concat(aws_alb_listener.https_listener.*.arn, aws_alb_listener.https_listener_1.*.arn)
}

output "asg_http_listener_arn" {
  value = aws_alb_listener.http_listener.arn
}
