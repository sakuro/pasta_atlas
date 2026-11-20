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
