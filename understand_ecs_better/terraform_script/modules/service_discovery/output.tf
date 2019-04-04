output "registry_arn" {
  value = "${aws_service_discovery_service.main.arn}"
}