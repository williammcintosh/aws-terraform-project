# Helpful output echo of the eventual public ip to the load balancer once TF apply has completed provisioning
output "alb_dns_name" {
  value       = aws_lb.mcintosh-terraform-lb.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.mcintosh-terraform-asg.name
  description = "The name of the Auto Scaling Group"
}
output "alb_security_group_id" {
  value = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}