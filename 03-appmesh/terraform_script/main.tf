provider "aws" {
  region                  = "ap-northeast-2"
  profile                 = "appmesh-test"
  version = "~> 2.4.0"
}

module "vpc_subnet_sg" {
  source = "modules/vpc_subnet_sg"
  vpc_cidr = "${var.vpc_cidr}"
  public_cidr1 = "${var.public_cidr1}"
  public_cidr2 = "${var.public_cidr2}"
  private_cidr1 = "${var.private_cidr1}"
  private_cidr2 = "${var.private_cidr2}"
}

module "ecs_instance_role" {
  source = "modules/ecs_instance_role"
}

module "ecs_task_role" {
  source = "modules/ecs_task_role"
}

module "alb" {
  source = "modules/alb"
  cluster = "${var.cluster}"
  environment = "${var.environment}"
  vpc_id = "${module.vpc_subnet_sg.vpc_id}"
  vpc_cidr = "${var.vpc_cidr}"
  public_subnet1_id = "${module.vpc_subnet_sg.public_subnet1_id}"
  public_subnet2_id = "${module.vpc_subnet_sg.public_subnet2_id}"
}

module "auto_scailing" {
  source = "modules/auto_scailing"
  cluster = "${var.cluster}"
  environment = "${var.environment}"
  instance_type = "${var.instance_type}"
  ecs_instance_profile_id = "${module.ecs_instance_role.ecs_instance_profile_id}"
  ecs_target_group_arn = "${module.alb.ecs_target_group_arn}"
  private_sg_id = "${module.vpc_subnet_sg.private_sg_id}"
  private_subnet_id = "${module.vpc_subnet_sg.private_subnet_id}"
  ecs_key_pair_name = "${var.key_pair}"
  max_instance_size = "${var.max_instance_size}"
  min_instance_size = "${var.min_instance_size}"
  desired_capacity = "${var.desired_capacity}"
}

resource "aws_ecs_cluster" "cluster" {
    name = "${var.cluster}"
}

resource "aws_appmesh_mesh" "mesh" {
    name = "${var.cluster}"
}

resource "aws_appmesh_virtual_service" "default_service" {
    name = "default.jayground.test"
    mesh_name = "${aws_appmesh_mesh.mesh.id}"

    spec {
        provider {
            virtual_node {
                virtual_node_name = "${aws_appmesh_virtual_node.default_service.name}"
            }
        }
    }
}

resource "aws_appmesh_virtual_node" "default_service" {
    name = "default_service_vn"
    mesh_name = "${aws_appmesh_mesh.mesh.id}"

    spec {
        backend {
            virtual_service {
                virtual_service_name = "${aws_appmesh_virtual_service.service.name}"
            }
        }

        listener {
            port_mapping {
                port = 3000
                protocol = "http"
            }
        }

        service_discovery {
            dns {
                hostname = "default.jayground.test"
            }
        }
    }
}

resource "aws_appmesh_virtual_router" "default_service" {
    name = "default_service_vr"
    mesh_name = "${aws_appmesh_mesh.mesh.id}"

    spec {
        listener {
            port_mapping {
                port = 3000
                protocol = "http"
            }
        }
    }
}

resource "aws_appmesh_route" "default_service" {
    name = "default_service_route"
    mesh_name = "${aws_appmesh_mesh.mesh.id}"
    virtual_router_name = "${aws_appmesh_virtual_router.default_service.name}"

    spec {
        http_route {
            match {
                prefix = "/"
            }

            action {
                weighted_target {
                    virtual_node = "${aws_appmesh_virtual_node.default_service.name}"
                    weight = 100
                }
            }
        }
    }
}

resource "aws_appmesh_virtual_service" "service" {
    name = "express.jayground.test"
    mesh_name = "${aws_appmesh_mesh.mesh.id}"

    spec {
        provider {
            virtual_node {
                virtual_node_name = "${aws_appmesh_virtual_node.service.name}"
            }
        }
    }
}

resource "aws_appmesh_virtual_node" "service" {
    name = "service_vn"
    mesh_name = "${aws_appmesh_mesh.mesh.id}"

    spec {
        listener {
            port_mapping {
                port = 3000
                protocol = "http"
            }
        }

        service_discovery {
            dns {
                hostname = "express.jayground.test"
            }
        }
    }
}

resource "aws_appmesh_virtual_router" "service" {
    name = "service_vr"
    mesh_name = "${aws_appmesh_mesh.mesh.id}"

    spec {
        listener {
            port_mapping {
                port = 3000
                protocol = "http"
            }
        }
    }
}

resource "aws_appmesh_route" "service" {
    name = "service_route"
    mesh_name = "${aws_appmesh_mesh.mesh.id}"
    virtual_router_name = "${aws_appmesh_virtual_router.service.name}"

    spec {
        http_route {
            match {
                prefix = "/"
            }

            action {
                weighted_target {
                    virtual_node = "${aws_appmesh_virtual_node.service.name}"
                    weight = 100
                }
            }
        }
    }
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.cluster}.${var.environment}"
  vpc         = "${module.vpc_subnet_sg.vpc_id}"
}

module "default_service_discovery" {
  source = "modules/service_discovery"
  cluster = "${var.cluster}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.main.id}"
  service_name = "${var.default_service_name}"
  environment = "${var.environment}"
  vpc_id = "${module.vpc_subnet_sg.vpc_id}"
}

module "default_service" {
  source = "modules/ecs_service_task"
  cluster = "${var.cluster}"
  cluster_id = "${aws_ecs_cluster.cluster.id}"
  environment = "${var.environment}"
  image = "${var.default_service_image}"
  app_port = "${var.app_port}"
  service_name = "${var.default_service_name}"
  log_group_prefix = "${var.default_service_name}"
  //ecs_service_role_arn = "${module.ecs_service_role.ecs_service_role_arn}"
  ecs_task_role_arn = "${module.ecs_task_role.ecs_task_role_arn}"
  ecs_target_group_arn = "${module.alb.ecs_target_group_arn}"
  aws_region = "${var.aws_region}"
  registry_arn = "${module.default_service_discovery.registry_arn}"
  virtual_node_name = "${aws_appmesh_virtual_node.default_service.name}"
  mesh_name = "${aws_appmesh_mesh.mesh.name}"
  private_subnet_id = "${module.vpc_subnet_sg.private_subnet_id}"
  private_sg_id = "${module.vpc_subnet_sg.private_sg_id}"
}

module "service_discovery" {
  source = "modules/service_discovery"
  cluster = "${var.cluster}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.main.id}"
  service_name = "${var.service_name}"
  environment = "${var.environment}"
  vpc_id = "${module.vpc_subnet_sg.vpc_id}"
}

module "service" {
  source = "modules/ecs_service_task"
  cluster = "${var.cluster}"
  cluster_id = "${aws_ecs_cluster.cluster.id}"
  environment = "${var.environment}"
  image = "${var.service_image}"
  app_port = "${var.app_port}"
  service_name = "${var.service_name}"
  log_group_prefix = "${var.service_name}"
  //ecs_service_role_arn = "${module.ecs_service_role.ecs_service_role_arn}"
  ecs_task_role_arn = "${module.ecs_task_role.ecs_task_role_arn}"
  ecs_target_group_arn = "${module.alb_rule_target.service_target_arn}"
  aws_region = "${var.aws_region}"
  registry_arn = "${module.service_discovery.registry_arn}"
  virtual_node_name = "${aws_appmesh_virtual_node.service.name}"
  mesh_name = "${aws_appmesh_mesh.mesh.name}"
  private_subnet_id = "${module.vpc_subnet_sg.private_subnet_id}"
  private_sg_id = "${module.vpc_subnet_sg.private_sg_id}"
}

module "alb_rule_target" {
  source = "modules/alb_rule_target"
  environment = "${var.environment}"
  cluster = "${var.cluster}"
  service_name = "${var.service_name}"
  vpc_id = "${module.vpc_subnet_sg.vpc_id}"
  listener_arn = "${module.alb.listener_arn}"
}

resource "aws_instance" "bastion" {
    ami = "ami-0eee4dcc71fced4cf" #hvm:ebs-ssd Ubuntu 16.04
    instance_type = "t2.micro"
    key_name = "${var.key_pair}"
    vpc_security_group_ids = ["${module.vpc_subnet_sg.public_sg_id}"]
    subnet_id = "${module.vpc_subnet_sg.public_subnet1_id}"
    associate_public_ip_address = true

    tags {
        Name = "${var.cluster}-bastion"
    }
}