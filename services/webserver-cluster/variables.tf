#-----modules/services/webserver-cluster/variables.tf

#-----Our variables go here to be used in interpolation syntax
variable "server_port" {
  description = "HTTP server port"
  default     = 8080
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
}

variable "instance_type" {
  description = "The type of EC2 instances to run (e.g. t2.micro)"
}

variable "min_size" {
  description = "The minimum number of EC2 instances in the ASG"
}

variable "max_size" {
  description = "The maximum number of EC2 instances in the ASG"
}

#-----These may need to be reviewed
variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database remote state"
}

variable "db_remote_state_key" {
  description = "The path for the database remote state in S3"
}
