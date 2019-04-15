provider "aws" {
  region                  = "ap-northeast-2"
  shared_credentials_file = "/Users/jaemyunlee/.aws/credentials"
  profile                 = "terraform-test"
}

##################################################
# Create VPC and Subnets and Security group      #
##################################################

resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = "${var.enable_dns_support}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "public_subnet1" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.public_cidr}"
  availability_zone = "ap-northeast-2a"

  tags {
    Name = "public-subnet-1"
  }
}

resource "aws_eip" "nat" {
  vpc = "true"
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public_subnet1.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "public subnet"
  }
}

resource "aws_route_table_association" "public_subnet1" {
  subnet_id      = "${aws_subnet.public_subnet1.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "public" {
  name = "public-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["1.1.1.1/32"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group" "private" {
  name   = "private-sg"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "private_subnet1" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.private_cidr1}"
  availability_zone = "ap-northeast-2a"

  tags {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.private_cidr2}"
  availability_zone = "ap-northeast-2c"

  tags {
    Name = "private-subnet-2"
  }
}

resource "aws_route_table" "private" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.gw.id}"
    }

    tags {
        Name = "private subnet"
    }
}

resource "aws_route_table_association" "private_subnet1" {
  subnet_id      = "${aws_subnet.private_subnet1.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "private_subnet2" {
  subnet_id      = "${aws_subnet.private_subnet2.id}"
  route_table_id = "${aws_route_table.private.id}"
}

##################################################
# Create RDS(free tier)                          #
##################################################

resource "aws_db_subnet_group" "test" {
  name       = "test"
  subnet_ids = ["${aws_subnet.private_subnet1.id}", "${aws_subnet.private_subnet2.id}"]
}

resource "aws_security_group" "db_instance" {
  name   = "db-sg"
  vpc_id = "${aws_vpc.main.id}"

}

resource "aws_security_group_rule" "allow_db_access" {
  type              = "ingress"
  from_port         = "${var.port}"
  to_port           = "${var.port}"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.db_instance.id}"
  cidr_blocks       = ["${var.vpc_cidr}"]
}

resource "aws_db_instance" "test" {
  identifier              = "testdb"
  engine                  = "${var.engine_name}"
  engine_version          = "${var.engine_version}"
  port                    = "${var.port}"
  name                    = "${var.database_name}"
  username                = "${var.username}"
  password                = "${var.password}"
  instance_class          = "db.t2.micro"
  multi_az                = "false"
  allocated_storage       = "${var.allocated_storage}"
  skip_final_snapshot     = "true"
  publicly_accessible     = "false"
  license_model           = "${var.license_model}"
  db_subnet_group_name    = "${aws_db_subnet_group.test.id}"
  vpc_security_group_ids  = ["${aws_security_group.db_instance.id}"]
}

##################################################
# Create EC2 instance in a public subnet         #
##################################################

resource "aws_instance" "public_ec2" {
  ami                         = "ami-00ca7ffe117e2fe91" #Ubuntu 16.04LTS hvm:ebs-ssd
  instance_type               = "t2.micro"
  key_name                    = "${var.keypair}"
  subnet_id                   = "${aws_subnet.public_subnet1.id}"
  vpc_security_group_ids      = ["${aws_security_group.public.id}"]
  associate_public_ip_address = true

  tags {
    Name = "public_ec2"
  }
}