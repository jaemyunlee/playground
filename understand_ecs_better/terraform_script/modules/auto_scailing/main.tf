data "template_file" "user_data" {
  template = "${file("${path.module}/template/user_data.sh")}"

  vars {
    cluster      = "${var.cluster}"
    environment       = "${var.environment}"
  }
}

data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name      = "name"
    values    = ["amzn-ami-2018.03.a-amazon-ecs-optimized"]
  }
}

resource "aws_launch_configuration" "ecs-launch-configuration" {
    name                        = "ecs-launch-configuration"
    image_id                    = "${data.aws_ami.amazonlinux.id}"
    instance_type               = "${var.instance_type}"
    iam_instance_profile        = "${var.ecs_instance_profile_id}"

    root_block_device {
      volume_type = "standard"
      volume_size = 8
      delete_on_termination = true
    }

    lifecycle {
      create_before_destroy = true
    }

    security_groups             = ["${var.private_sg_id}"]
    associate_public_ip_address = "false"
    key_name                    = "${var.ecs_key_pair_name}"
    user_data                   = "${data.template_file.user_data.rendered}"
}

resource "aws_autoscaling_group" "ecs-autoscaling-group" {
    name                        = "ecs-autoscaling-group"
    max_size                    = "${var.max_instance_size}"
    min_size                    = "${var.min_instance_size}"
    desired_capacity            = "${var.desired_capacity}"
    vpc_zone_identifier         = ["${var.private_subnet_id}"]
    launch_configuration        = "${aws_launch_configuration.ecs-launch-configuration.name}"
    health_check_type           = "EC2"
}