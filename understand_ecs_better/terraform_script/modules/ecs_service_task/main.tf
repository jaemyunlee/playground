/*data "aws_ecs_task_definition" "def" {
  task_definition = "${aws_ecs_task_definition.task-definition.family}"
}*/

resource "aws_cloudwatch_log_group" "ecs" {
  name = "/${var.environment}/${var.cluster}"
}

resource "aws_ecs_task_definition" "task-definition" {
    family                = "${var.service_name}"
    task_role_arn         = "${var.ecs_task_role_arn}"
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
            "awslogs-group": "/${var.environment}/${var.cluster}",
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

resource "aws_ecs_service" "service" {
  	name            = "${var.environment}-${var.service_name}"
  	//iam_role        = "${var.ecs_service_role_arn}"
  	cluster         = "${var.cluster_id}"
  	//task_definition = "${aws_ecs_task_definition.task-definition.family}:${max("${aws_ecs_task_definition.task-definition.revision}", "${data.aws_ecs_task_definition.def.revision}")}"
  	task_definition = "${aws_ecs_task_definition.task-definition.family}:${aws_ecs_task_definition.task-definition.revision}"
  	desired_count   = 1

  	load_balancer {
    	target_group_arn  = "${var.ecs_target_group_arn}"
    	container_port    = "${var.app_port}"
    	container_name    = "${var.environment}-${var.service_name}"
	}

	service_registries {
	    registry_arn = "${var.registry_arn}"
	    container_port = "${var.app_port}"
	    container_name = "${var.environment}-${var.service_name}"
	}
}