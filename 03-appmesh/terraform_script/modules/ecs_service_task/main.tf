/*
The awslogs log driver can send log streams to existing log groups in CloudWatch Logs,
but it cannot create log groups. Before you launch any tasks that use the awslogs log driver,
you should ensure the log groups that you intend your containers to use are created.
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html
*/
resource "aws_cloudwatch_log_group" "ecs" {
  name = "/${var.environment}/${var.cluster}/${var.service_name}"
}
/*
resource "aws_ecs_task_definition" "task-definition" {
    family                = "${var.service_name}"
    task_role_arn         = "${var.ecs_task_role_arn}"
    network_mode          = "awsvpc"
    depends_on = [ "aws_cloudwatch_log_group.ecs", ]
    container_definitions = <<DEFINITION
[
    {
        "essential": true,
        "image": "${var.image}",
        "name": "${var.environment}-${var.service_name}",
        "cpu": 250,
        "memory": 250,
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "/${var.environment}/${var.cluster}/${var.service_name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "${var.log_group_prefix}"
          }
        },
        "portMappings": [{
          "protocol": "tcp",
          "containerPort": ${var.app_port}
        }],
        "environment": [
          {
            "name": "PORT",
            "value": "${var.app_port}"
          }
        ]
    }
]
DEFINITION
}
*/

resource "aws_ecs_task_definition" "task-definition" {
    family                = "${var.service_name}"
    task_role_arn         = "${var.ecs_task_role_arn}"
    network_mode          = "awsvpc"
    depends_on = [ "aws_cloudwatch_log_group.ecs", ]
    container_definitions = <<DEFINITION
[
    {
        "essential": true,
        "image": "${var.image}",
        "name": "${var.environment}-${var.service_name}",
        "cpu": 250,
        "memory": 250,
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "/${var.environment}/${var.cluster}/${var.service_name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "${var.log_group_prefix}"
          }
        },
        "portMappings": [{
          "protocol": "tcp",
          "containerPort": ${var.app_port}
        }],
        "environment": [
          {
            "name": "PORT",
            "value": "${var.app_port}"
          }
        ]
    },
    {
        "essential": false,
        "image": "120387605022.dkr.ecr.ap-northeast-2.amazonaws.com/aws-xray-daemon",
        "name": "xray-daemon",
        "user": "1337",
        "cpu": 32,
        "memory": 64,
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "/${var.environment}/${var.cluster}/${var.service_name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "xray"
          }
        },
        "portMappings": [{
          "protocol": "udp",
          "containerPort": 2000
        }]
    },
    {
        "essential": true,
        "image": "120387605022.dkr.ecr.ap-northeast-2.amazonaws.com/aws-appmesh-envoy",
        "memoryReservation": 100,
        "name": "envoy",
        "user": "1337",
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "/${var.environment}/${var.cluster}/${var.service_name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "envoy"
          }
        },
        "environment": [
            {
                "name": "APPMESH_VIRTUAL_NODE_NAME",
                "value": "mesh/${var.mesh_name}/virtualNode/${var.virtual_node_name}"
            },
            {
                "name": "ENVOY_LOG_LEVEL",
                "value": "debug"
            },
            {
                "name": "ENABLE_ENVOY_XRAY_TRACING",
                "value": "1"
            }
        ]
    }
]
DEFINITION
}

resource "aws_ecs_service" "service" {
  	name            = "${var.service_name}"
  	//iam_role        = "${var.ecs_service_role_arn}"
  	cluster         = "${var.cluster_id}"
  	//task_definition = "${aws_ecs_task_definition.task-definition.family}:${max("${aws_ecs_task_definition.task-definition.revision}", "${data.aws_ecs_task_definition.def.revision}")}"
  	//task_definition = "${aws_ecs_task_definition.task-definition.family}:${aws_ecs_task_definition.task-definition.revision}"
  	task_definition = "${aws_ecs_task_definition.task-definition.arn}"
  	desired_count   = 1
  	network_configuration = {
  	    subnets = ["${var.private_subnet_id}", ]
  	    security_groups = ["${var.private_sg_id}",]
  	}

  	load_balancer {
    	target_group_arn  = "${var.ecs_target_group_arn}"
    	container_port    = "${var.app_port}"
    	container_name    = "${var.environment}-${var.service_name}"
	}

	service_registries {
	    registry_arn = "${var.registry_arn}"
	    //container_port = "${var.app_port}"
	    container_name = "${var.environment}-${var.service_name}"
	}

	depends_on = ["aws_ecs_task_definition.task-definition"]
}