output "ecs_service_role_arn" {
  value = "${aws_iam_role.ecs-service-role.arn}"
}