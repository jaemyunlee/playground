output "ecs_target_group_arn" {
  value = "${aws_alb_target_group.ecs-target-group.arn}"
}

output "listener_arn" {
  value = "${aws_alb_listener.alb-listener.arn}"
}