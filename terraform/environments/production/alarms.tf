resource "aws_sns_topic" "alarms" {
  name = "${var.app_name}-${var.environment}-alarms"
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count     = var.alarm_email == null ? 0 : 1
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# A message reaches the dead-letter queue after five failed receives. It is kept for
# 14 days, so an alarm is the only way anyone notices it.
resource "aws_cloudwatch_metric_alarm" "s3_cleanup_dlq" {
  alarm_name          = "${var.app_name}-${var.environment}-s3-cleanup-dlq-not-empty"
  alarm_description   = "Messages are waiting in the s3-cleanup dead-letter queue."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = aws_sqs_queue.s3_cleanup_dlq.name }
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# An invocation error is an unhandled exception or a timeout. A 5xx that Puma returns
# normally does not count here; the CloudFront alarm below covers it.
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${var.app_name}-${var.environment}-app-errors"
  alarm_description   = "The app function failed to handle a request."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = aws_lambda_function.app.function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Requests beyond the reserved concurrency (var.app_reserved_concurrency) are rejected.
resource "aws_cloudwatch_metric_alarm" "app_throttles" {
  alarm_name          = "${var.app_name}-${var.environment}-app-throttles"
  alarm_description   = "Requests to the app function were throttled."
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  dimensions          = { FunctionName = aws_lambda_function.app.function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# CloudFront reports its metrics in us-east-1, and an alarm can only notify a topic in its
# own region, so this alarm needs a topic of its own. The email subscription has to be
# confirmed separately.
resource "aws_sns_topic" "alarms_us_east_1" {
  provider = aws.us_east_1
  name     = "${var.app_name}-${var.environment}-alarms"
}

resource "aws_sns_topic_subscription" "alarm_email_us_east_1" {
  provider  = aws.us_east_1
  count     = var.alarm_email == null ? 0 : 1
  topic_arn = aws_sns_topic.alarms_us_east_1.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# With little traffic one failed request is a high rate, which is acceptable: any 5xx
# deserves a look.
resource "aws_cloudwatch_metric_alarm" "app_5xx_rate" {
  provider            = aws.us_east_1
  alarm_name          = "${var.app_name}-${var.environment}-app-5xx-rate"
  alarm_description   = "5% or more of the requests to the application domain failed with a 5xx."
  namespace           = "AWS/CloudFront"
  metric_name         = "5xxErrorRate"
  dimensions          = { DistributionId = aws_cloudfront_distribution.app.id, Region = "Global" }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms_us_east_1.arn]
  ok_actions    = [aws_sns_topic.alarms_us_east_1.arn]
}
