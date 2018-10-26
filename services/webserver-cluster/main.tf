#-----modules/services/webserver-cluster/main.tf

#-----Invisible read-only list of AZs for this region to be used later
data "aws_availability_zones" "all" {}

#-----Read only data pulling from S3 storage tfstate to capture mysql
#-----db parameters
data "terraform_remote_state" "db" {
  backend = "s3"

  #  environment = "${terraform.workspace}"

  config {
    bucket = "${var.db_remote_state_bucket}"
    key    = "${var.db_remote_state_key}"
    region = "us-east-1"
  }
}

#-----Target a local file as a template and define values with a vars map
#-----you wish to generate into the outputted template file
data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    server_port = "${var.server_port}"
    db_address  = "${data.terraform_remote_state.db.address}"
    db_port     = "${data.terraform_remote_state.db.port}"
  }
}

#-----Define a launch config - specifies how to configure each
#-----EC2 resource within an Auto Scaling Group
resource "aws_launch_configuration" "example" {
  image_id        = "ami-40d28157"
  instance_type   = "${var.instance_type}"
  security_groups = ["${aws_security_group.instance.id}"]

  #-----Specify the data template defined above as a rendered/generated
  #-----output for the resources in this Auto Scaling Group
  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

#-----Create the ASG defining values using interpolation and point it
#-----toward the Loadbalancer resource created below
resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]

  load_balancers    = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}

#-----Define an Elastic Loadbalancer that will route traffic for the nodes
#-----within the ASG
resource "aws_elb" "example" {
  name               = "${var.cluster_name}-elb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:${var.server_port}/"
    interval            = 30
  }
}

#-----Create Sec Groups and rules to restrict access through the firewall
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-8080"
}

resource "aws_security_group" "elb" {
  name = "${var.cluster_name}-elb"
}

resource "aws_security_group_rule" "allow_8080_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.instance.id}"

  from_port   = "${var.server_port}"
  to_port     = "${var.server_port}"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
