provider "aws" {
 region = "us-east-2"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  # ami = "ami-0fb653ca2d3203ac1"
  # server_text = "I'm terraforming from the production environment!"

  cluster_name           = var.cluster_name
  db_remote_state_bucket = var.db_remote_state_bucket
  db_remote_state_key    = var.db_remote_state_key

  # IRL prod should use a bigger one, but those aren't free
  instance_type = "t2.micro" 
  min_size = 2
  max_size = 10

  #Make autoscaling depend upon hours of the day instead of hard coded
  enable_autoscaling = true 

	custom_tags = {
		Owner     = "Will McIntosh"
		ManagedBy = "terraform"
	}
}

# resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
#     scheduled_action_name = "scale-out-during-business-hours"
#     min_size = 2
#     max_size = 10
#     desired_capacity = 10
#     recurrence = "0 9 * * *"

#     autoscaling_group_name = module.webserver_cluster.asg_name
# }

# resource "aws_autoscaling_schedule" "scale_in_at_night" {
#     scheduled_action_name = "scale-in-at-night"
#     min_size = 2
#     max_size = 10
#     desired_capacity = 2
#     recurrence = "0 17 * * *"

#     autoscaling_group_name = module.webserver_cluster.asg_name
# }

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "prod/services/webserver-cluster/terraform.tfstate"
  }
}