output "vpc_id" {
  value = "${aws_vpc.main.id}"
}
output "public_subnet1_id" {
  value = "${aws_subnet.public_subnet1.id}"
}
output "public_subnet2_id" {
  value = "${aws_subnet.public_subnet2.id}"
}
output "public_sg_id" {
  value = "${aws_security_group.public.id}"
}
output "private_subnet_id" {
  value = "${aws_subnet.private_subnet1.id}"
}
output "private_sg_id" {
  value = "${aws_security_group.private.id}"
}