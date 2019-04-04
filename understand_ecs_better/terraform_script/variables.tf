variable "vpc_cidr" {
  default = "10.1.0.0/16"
}
variable "public_cidr1" {
  default = "10.1.1.0/24"
}
variable "public_cidr2" {
  default = "10.1.2.0/24"
}
variable "private_cidr1" {
  default = "10.1.3.0/24"
}
variable "private_cidr2" {
  default = "10.1.4.0/24"
}

variable "cluster" {}
variable "environment" {}
variable "default_service_name" {
  default = "default_service"
}
variable "default_service_image" {}
variable "service_name" {}
variable "service_image" {}
variable "aws_region" {}
variable "log_group_prefix" {}
variable "app_port" {}

variable "instance_type" {
  default = "t2.micro"
}
variable "key_pair" {}
variable "max_instance_size" {}
variable "min_instance_size" {}
variable "desired_capacity" {}

