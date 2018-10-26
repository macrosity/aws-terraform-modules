#-----modules/services/webserver-cluster/outputs.tf

#-----Create an output variable based on the DNS name of the ELB
output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.example.name}"
}

output "db_address" {
  value = "${data.terraform_remote_state.db.address}"
}

output "db_port" {
  value = "${data.terraform_remote_state.db.port}"
}
