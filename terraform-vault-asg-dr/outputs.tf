output "lb_dns" {
  description = "Load Balancer DNS name"
  value       = aws_lb.vault-asg-lb.dns_name
}

output "kms_key_id" {
  description = "AWS KMS key ID"
  value       = aws_kms_key.vault-asg.id
}

output "asg_name" {
  description = "Auto Scaling Group Name"
  value       = aws_autoscaling_group.asg.name
}

output "asg_lb" {
  description = "Auto Scaling Group Load Balancers"
  value       = aws_autoscaling_group.asg.load_balancers
}