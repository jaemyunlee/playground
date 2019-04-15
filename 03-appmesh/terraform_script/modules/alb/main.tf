resource "aws_security_group" "alb" {
  name   = "${var.cluster}-${var.environment}-alb-sg"
  vpc_id = "${var.vpc_id}"

  ingress {
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      protocol    = -1
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["${var.vpc_cidr}"]
    }
}

resource "aws_alb" "ecs-load-balancer" {
    name                = "alb-${var.environment}-${var.cluster}"
    security_groups     = ["${aws_security_group.alb.id}"]
    subnets             = ["${var.public_subnet1_id}", "${var.public_subnet2_id}"]

    tags {
      Name = "alb-${var.environment}-${var.cluster}"
    }
}

resource "aws_alb_listener" "alb-listener" {
    load_balancer_arn = "${aws_alb.ecs-load-balancer.arn}"
    port              = "80"
    protocol          = "HTTP"

    default_action {
        target_group_arn = "${aws_alb_target_group.ecs-target-group.arn}"
        type             = "forward"
    }
}

resource "aws_alb_target_group" "ecs-target-group" {
    name                = "${var.environment}-${var.cluster}-target-group"
    port                = "80"
    protocol            = "HTTP"
    vpc_id              = "${var.vpc_id}"
    target_type          = "ip"

    health_check {
        healthy_threshold   = "5"
        unhealthy_threshold = "2"
        interval            = "30"
        matcher             = "200"
        path                = "/health/"
        port                = "3000"
        protocol            = "HTTP"
        timeout             = "5"
    }

    tags {
      Name = "${var.environment}-${var.cluster}-target-group"
    }

    depends_on = ["aws_alb.ecs-load-balancer"]
}