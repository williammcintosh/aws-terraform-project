resource "aws_launch_configuration" "mcintosh-terraform-launch-config" {
  image_id        = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]

  user_data       = templatefile("${path.module}/user-data.sh", {
    server_port   = var.server_port
    db_address    = data.terraform_remote_state.db.outputs.address
    db_port       = data.terraform_remote_state.db.outputs.port
    server_text   = var.server_text
  })
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "mcintosh-terraform-asg" {
  name = "${var.cluster_name}-${aws_launch_configuration.mcintosh-terraform-launch-config.name}"
  launch_configuration = aws_launch_configuration.mcintosh-terraform-launch-config.name
  vpc_zone_identifier  = data.aws_subnets.default.ids                             
  target_group_arns = [aws_lb_target_group.asg.arn]
  min_size = var.min_size
  max_size = var.max_size
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = {
      for key, value in var.custom_tags:
      key => upper(value)
      if key != "Name"
    }
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnets" "default" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
    filter {
        name   = "availability-zone"
        values = ["us-east-2a", "us-east-2b", "us-east-2c"]
    }
}

resource "aws_security_group" "alb" {
 name = "${var.cluster_name}-alb"
}

resource "aws_lb" "mcintosh-terraform-lb" {
  name               = "mcintosh-terraform-asg"
  # name               = "${var.cluster_name}-asg"
  load_balancer_type = "application"
  # Which VPC subnets to communicate on - default is WIDE OPEN
  subnets            = data.aws_subnets.default.ids 
  # Security group to allow incoming requests on 80
  security_groups    = [aws_security_group.alb.id]  
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.mcintosh-terraform-lb.arn
    port              = local.http_port
    protocol          = "HTTP"

    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "404: Page not found"
        status_code  = 404
      }
    }
}

resource "aws_lb_target_group" "asg" {
    name     = "mcintosh-terraform-asg"
    port     = var.server_port
    protocol = "HTTP"
    vpc_id   = data.aws_vpc.default.id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
        path_pattern {
            values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

resource "aws_security_group_rule" "allow_http_inbound" {
 type = "ingress"
 security_group_id = aws_security_group.alb.id
 from_port = local.http_port
 to_port = local.http_port
 protocol = local.tcp_protocol
 cidr_blocks = local.all_ips
}
resource "aws_security_group_rule" "allow_all_outbound" {
 type = "egress"
 security_group_id = aws_security_group.alb.id
 from_port = local.any_port
 to_port = local.any_port
 protocol = local.any_protocol
 cidr_blocks = local.all_ips
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0
  scheduled_action_name = "${var.cluster_name}-scale-out-during-business-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.mcintosh-terraform-asg.name
}
resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count                  = var.enable_autoscaling ? 1 : 0
  scheduled_action_name  = "${var.cluster_name}-scale-in-at-night"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.mcintosh-terraform-asg.name
}

data "terraform_remote_state" "db" {
    backend = "s3"
    config = {
        bucket = var.db_remote_state_bucket
        key    = var.db_remote_state_key
        region = "us-east-2"
    }
}
locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

# Get default VPC for region
data "aws_vpc" "default" {
  default = true
}
