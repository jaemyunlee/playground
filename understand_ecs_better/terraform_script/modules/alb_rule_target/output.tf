output "service_target_arn" {
  value = "${aws_alb_target_group.main.arn}"
}