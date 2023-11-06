variable "cluster_name" {
    description = "The name to use for all the cluster resources"
    type = string
    default = "mcintosh-terraform-instance"
}
variable "db_remote_state_bucket" {
    description = "The name of the S3 bucket for the database's remote state"
    type = string
    default = "mcintosh-terraform-state-storage"
}
variable "db_remote_state_key" {
    description = "The path for the database's remote state in S3"
    type = string
    default = "stage/data-stores/postgres/terraform.tfstate"
}

# These allow different clusters in prod vs stage environments
variable "instance_type" {
 description = "The type of EC2 Instances to run (e.g. t2.micro)"
 type = string
 default = "t2.micro"
}
variable "min_size" {
 description = "The minimum number of EC2 Instances in the ASG"
 type = number
 default = 2
}
variable "max_size" {
 description = "The maximum number of EC2 Instances in the ASG"
 type = number
 default = 4
}

variable "ami" {
 description = "The AMI to run in the cluster"
 type = string
 default = "ami-0fb653ca2d3203ac1"
}
variable "server_text" {
 description = "The text the web server should return"
 type = string
 default = "Hello, World! I'm terraforming, bitches!"
}

variable "custom_tags" {
    description = "Custom tags to set on the Instances in the ASG"
    type = map(string)
    default = {}
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}