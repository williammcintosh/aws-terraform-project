provider "aws" {
 region = "us-east-2"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  ami = "ami-0fb653ca2d3203ac1"
  server_text = "I'm terraforming from the staging environment!"

  cluster_name           = var.cluster_name
  db_remote_state_bucket = var.db_remote_state_bucket
  db_remote_state_key    = var.db_remote_state_key

  # The stage environment needs a smaller instance type
  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}

resource "aws_security_group_rule" "allow_testing_inbound" {
    type = "ingress"
    security_group_id = module.webserver_cluster.alb_security_group_id
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}
