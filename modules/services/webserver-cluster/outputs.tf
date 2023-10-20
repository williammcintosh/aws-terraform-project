# Helpful output echo of the eventual public ip to the load balancer once TF apply has completed provisioning
output "alb_dns_name" {
  value       = aws_lb.mcintosh-terraform-lb.dns_name
  description = "The domain name of the load balancer"
}