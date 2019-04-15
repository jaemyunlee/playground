resource "aws_iam_role" "ecs-task-role" {
    name                = "ecs-task-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.ecs-task-policy.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch_role" {
  role       = "${aws_iam_role.ecs-task-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_xray_role" {
  role       = "${aws_iam_role.ecs-task-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayFullAccess"
}

data "aws_iam_policy_document" "ecs-task-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ecs-tasks.amazonaws.com"]
        }
    }
}