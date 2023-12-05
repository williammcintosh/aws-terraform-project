locals {
	http_port    = 3000
	any_port     = 0
	any_protocol = "-1"
	tcp_protocol = "tcp"
	all_ips      = ["0.0.0.0/0"]
    region       = "us-east-2"
}

provider "aws" {
	region = local.region
}

# terraform {
# 	# Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
# 	backend "s3" {
# 		key = "stage/services/rust_backend/terraform.tfstate"
# 	}
# }

# moved to modules/services/ecr-registry
resource "aws_ecr_repository" "app_ecr_repo" {
	name = "rust-backend"
}

resource "aws_ecs_cluster" "rust_backend_cluster" {
	name = "rust-backend-cluster"
}

# Get default VPC for region
data "aws_vpc" "default" {
	default = true
}

# Get default subnet within the aws_vpc
data "aws_subnets" "default" {
	filter {
		name   = "vpc-id"
		values = [data.aws_vpc.default.id]
	}

	# Add this filter to select only the subnets in the us-east-2[a-c] Availability Zone because 2d doesn't support t2.micro
	filter {
		name   = "availability-zone"
		values = ["${local.region}a", "${local.region}b", "${local.region}c"]
	}
}

# Add fargate serverless resources
resource "aws_ecs_task_definition" "app_task" {
	family                   = "rust-backend-task" # Name your task
	container_definitions    = <<DEFINITION
  [
    {
      "name": "rust-backend-task",
      "image": "${aws_ecr_repository.app_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${local.http_port},
          "hostPort": ${local.http_port}
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
	requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
	network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
	memory                   = 512         # Specify the memory the container requires
	cpu                      = 256         # Specify the CPU the container requires
	execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
	name               = "ecsTaskExecutionRole"
	assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
	statement {
		actions = ["sts:AssumeRole"]

		principals {
			type        = "Service"
			identifiers = ["ecs-tasks.amazonaws.com"]
		}
	}
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
	role       = aws_iam_role.ecsTaskExecutionRole.name
	policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security group to allow ALB listeners to allow incoming reqs on 80 and allow all outgoing (for itself to communicate with VPCs)
resource "aws_security_group" "alb" {
	name = "rust-backend-alb"
}
resource "aws_security_group_rule" "allow_http_inbound" {
	type              = "ingress"
	security_group_id = aws_security_group.alb.id
	from_port         = local.http_port
	to_port           = local.http_port
	protocol          = local.tcp_protocol
	cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
	type              = "egress"
	security_group_id = aws_security_group.alb.id
	from_port         = local.any_port
	to_port           = local.any_port
	protocol          = local.any_protocol
	cidr_blocks       = local.all_ips
}

resource "aws_alb" "application_load_balancer" {
	name               = "load-balancer-dev" #load balancer name
	load_balancer_type = "application"
	subnets = data.aws_subnets.default.ids
	# security group
	security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "asg" {
	name     = "rust-backend-asg"
	port     = local.http_port
	protocol = "HTTP"
	target_type = "ip"
	vpc_id   = data.aws_vpc.default.id
}

# This is what forwards the actual requests to the correct destination behind the load balancer
resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_alb.application_load_balancer.arn
	port              = local.http_port
	protocol          = "HTTP"

	default_action {
		type             = "forward"
		target_group_arn = aws_lb_target_group.asg.arn
	}
}

resource "aws_ecs_service" "rust_backend_service" {
	name            = "rust-backend-service"     # Name the service
	cluster         = aws_ecs_cluster.rust_backend_cluster.id   # Reference the created Cluster
	task_definition = aws_ecs_task_definition.app_task.arn # Reference the task that the service will spin up
	launch_type     = "FARGATE"
	desired_count   = 3 # Set up the number of containers to 3

	load_balancer {
		target_group_arn = aws_lb_target_group.asg.arn
		container_name   = aws_ecs_task_definition.app_task.family
		container_port   = local.http_port # Specify the container port
	}

	network_configuration {
		subnets          = data.aws_subnets.default.ids
		assign_public_ip = true     # Provide the containers with public IPs
		security_groups  = [aws_security_group.alb.id] # Set up the security group
	}
}

# create security groups that will only allow the traffic from the created load balancer
resource "aws_security_group" "service_security_group" {
	ingress {
		from_port = 0
		to_port   = 0
		protocol  = "-1"
		# Only allowing traffic in from the load balancer security group
		security_groups = [aws_security_group.alb.id]
	}

	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

output "app_url" {
	value = aws_alb.application_load_balancer.dns_name
}