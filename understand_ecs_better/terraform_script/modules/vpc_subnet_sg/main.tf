resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "public_subnet1" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.public_cidr1}"
  availability_zone = "ap-northeast-2a"

  tags {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.public_cidr2}"
  availability_zone = "ap-northeast-2c"

  tags {
    Name = "public-subnet-2"
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

resource "aws_route_table_association" "public_subnet2" {
  subnet_id      = "${aws_subnet.public_subnet2.id}"
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

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group" "private" {
  name   = "private-sg"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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