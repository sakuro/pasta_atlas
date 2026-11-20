# The real package is uploaded by the deploy workflow; Terraform only needs something
# to create the functions with.
data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/.terraform/placeholder.zip"

  source {
    content  = "def handler(event:, context:) = nil\n"
    filename = "placeholder.rb"
  }
}

locals {
  lambda_environment = {
    HANAMI_ENV                        = var.environment
    SSM_PARAMETER_PREFIX              = "/${var.app_name}/${var.environment}"
    APP_BASE_URL                      = "https://${var.app_domain_name}"
    S3_BUCKET                         = aws_s3_bucket.mapshots.bucket
    CLOUDFRONT_BASE_URL               = "https://${aws_cloudfront_distribution.mapshots.domain_name}"
    SQS_S3_CLEANUP_QUEUE_URL          = aws_sqs_queue.s3_cleanup.url
    SQS_STORAGE_CALCULATION_QUEUE_URL = aws_sqs_queue.storage_calculation.url
    PRESIGNED_URL_EXPIRY              = tostring(var.presigned_url_expiry)
    GITHUB_CLIENT_ID                  = var.github_client_id
    DISCORD_CLIENT_ID                 = var.discord_client_id
    # /var/task is read-only and Bundler needs a writable home in every function.
    HOME = "/tmp"
  }

  lambda_vpc = {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.app.id]
  }
}

resource "aws_lambda_function" "app" {
  function_name = local.lambda_function_names["app"]
  role          = aws_iam_role.app.arn
  runtime       = var.lambda_runtime
  architectures = ["arm64"]
  handler       = "run.sh"
  memory_size   = var.app_memory_size
  timeout       = 30
  layers        = [var.web_adapter_layer_arn]

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  reserved_concurrent_executions = var.app_reserved_concurrency

  vpc_config {
    subnet_ids         = local.lambda_vpc.subnet_ids
    security_group_ids = local.lambda_vpc.security_group_ids
  }

  environment {
    variables = merge(local.lambda_environment, {
      AWS_LAMBDA_EXEC_WRAPPER      = "/opt/bootstrap"
      AWS_LWA_PORT                 = "7000"
      AWS_LWA_READINESS_CHECK_PATH = "/up"
    })
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy_attachment.app_lambda_vpc]

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_function_url" "app" {
  function_name      = aws_lambda_function.app.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "app_url" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.app.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# Function URLs created after October 2025 also need lambda:InvokeFunction.
resource "aws_lambda_permission" "app_url_invoke" {
  statement_id             = "FunctionURLAllowInvokeAction"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.app.function_name
  principal                = "*"
  invoked_via_function_url = true
}

resource "aws_lambda_function" "s3_cleanup" {
  function_name = local.lambda_function_names["s3-cleanup"]
  role          = aws_iam_role.app.arn
  runtime       = var.lambda_runtime
  architectures = ["arm64"]
  handler       = "lambda_function.LambdaFunction::S3Cleanup.process"
  memory_size   = 512
  timeout       = local.worker_timeout_seconds

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  vpc_config {
    subnet_ids         = local.lambda_vpc.subnet_ids
    security_group_ids = local.lambda_vpc.security_group_ids
  }

  environment {
    variables = local.lambda_environment
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy_attachment.app_lambda_vpc]

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_function" "storage_calculation" {
  function_name = local.lambda_function_names["storage-calculation"]
  role          = aws_iam_role.app.arn
  runtime       = var.lambda_runtime
  architectures = ["arm64"]
  handler       = "lambda_function.LambdaFunction::StorageCalculation.process"
  memory_size   = 512
  timeout       = local.worker_timeout_seconds

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  vpc_config {
    subnet_ids         = local.lambda_vpc.subnet_ids
    security_group_ids = local.lambda_vpc.security_group_ids
  }

  environment {
    variables = local.lambda_environment
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy_attachment.app_lambda_vpc]

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_function" "task" {
  function_name = local.lambda_function_names["task"]
  role          = aws_iam_role.app.arn
  runtime       = var.lambda_runtime
  architectures = ["arm64"]
  handler       = "lambda_function.LambdaFunction::Task.process"
  memory_size   = 1024
  timeout       = 900

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  vpc_config {
    subnet_ids         = local.lambda_vpc.subnet_ids
    security_group_ids = local.lambda_vpc.security_group_ids
  }

  environment {
    variables = local.lambda_environment
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy_attachment.app_lambda_vpc]

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_event_source_mapping" "s3_cleanup" {
  event_source_arn        = aws_sqs_queue.s3_cleanup.arn
  function_name           = aws_lambda_function.s3_cleanup.arn
  batch_size              = 1
  function_response_types = ["ReportBatchItemFailures"]

  # Keeps database connections within what the RDS instance accepts.
  scaling_config {
    maximum_concurrency = 2
  }
}

resource "aws_lambda_event_source_mapping" "storage_calculation" {
  event_source_arn        = aws_sqs_queue.storage_calculation.arn
  function_name           = aws_lambda_function.storage_calculation.arn
  batch_size              = 1
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = 2
  }
}
