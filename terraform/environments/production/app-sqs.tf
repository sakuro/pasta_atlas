resource "aws_sqs_queue" "s3_cleanup" {
  name = "${var.app_name}-${var.environment}-s3-cleanup"
}

resource "aws_iam_role" "pipe" {
  name               = "${var.app_name}-${var.environment}-pipe"
  assume_role_policy = data.aws_iam_policy_document.pipe_assume_role.json
}

data "aws_iam_policy_document" "pipe_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["pipes.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "pipe" {
  name   = "${var.app_name}-${var.environment}-pipe"
  policy = data.aws_iam_policy_document.pipe.json
}

data "aws_iam_policy_document" "pipe" {
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [aws_sqs_queue.s3_cleanup.arn]
  }

  statement {
    actions   = ["ecs:RunTask"]
    resources = [aws_ecs_task_definition.app.arn]
  }

  statement {
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.app.arn,
      aws_iam_role.execution.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "pipe" {
  role       = aws_iam_role.pipe.name
  policy_arn = aws_iam_policy.pipe.arn
}

resource "aws_pipes_pipe" "s3_cleanup" {
  name     = "${var.app_name}-${var.environment}-s3-cleanup"
  role_arn = aws_iam_role.pipe.arn
  source   = aws_sqs_queue.s3_cleanup.arn
  target   = aws_ecs_cluster.main.arn

  source_parameters {
    sqs_queue_parameters {
      batch_size = 1
    }
  }

  target_parameters {
    input_template = jsonencode({
      containerOverrides = [{
        name    = var.app_name
        command = ["bundle", "exec", "rake", "sqs:delete_s3_prefix[<$.body>]"]
      }]
    })

    ecs_task_parameters {
      task_definition_arn = aws_ecs_task_definition.app.arn
      launch_type         = "FARGATE"
      task_count          = 1

      network_configuration {
        aws_vpc_configuration {
          subnets          = data.aws_subnets.default.ids
          security_groups  = [aws_security_group.app.id]
          assign_public_ip = "ENABLED"
        }
      }
    }
  }
}
