resource "aws_alb_target_group" "main" {
    name                = "${var.service_name}-target-group"
    port                = "80"
    protocol            = "HTTP"
    vpc_id              = "${var.vpc_id}"

    health_check {
        healthy_threshold   = "5"
        unhealthy_threshold = "2"
        interval            = "30"
        matcher             = "200"
        path                = "/health/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = "5"
    }

    tags {
      Name = "${var.service_name}-target-group"
    }
}

resource "aws_lb_listener_rule" "service" {
    listener_arn = "${var.listener_arn}"

    action {
      type = "forward"
      target_group_arn = "${aws_alb_target_group.main.arn}"
    }

    condition {
      field = "path-pattern"
      values = ["/api/*"]
    }
}
