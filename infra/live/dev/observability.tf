locals {
  ingest_fn = module.ingest.function_name
  worker_fn = module.worker.function_name
  queue     = module.queue.queue_name
}


resource "aws_cloudwatch_log_group" "ingest" {
  name              = "/aws/lambda/${local.ingest_fn}"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "worker" {
  name              = "/aws/lambda/${local.worker_fn}"
  retention_in_days = 7
}


resource "aws_sns_topic" "ops" {
  name = "ops-alerts-dev-sg1"
}

resource "aws_sns_topic_subscription" "ops_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.ops.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}




resource "aws_cloudwatch_metric_alarm" "sqs_age_high" {
  alarm_name          = "dev-sg1-sqs-age>=60s-5m"
  alarm_description   = "SQS oldest message age high (worker may be failing or behind)"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 60
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    QueueName = local.queue
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.ops.arn]
  ok_actions         = [aws_sns_topic.ops.arn]
}


resource "aws_cloudwatch_metric_alarm" "ingest_errors" {
  alarm_name          = "dev-sg1-ingest-errors>=1-5m"
  alarm_description   = "Ingest Lambda reported errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    FunctionName = local.ingest_fn
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.ops.arn]
  ok_actions         = [aws_sns_topic.ops.arn]
}


resource "aws_cloudwatch_metric_alarm" "worker_errors" {
  alarm_name          = "dev-sg1-worker-errors>=1-5m"
  alarm_description   = "Worker Lambda reported errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    FunctionName = local.worker_fn
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.ops.arn]
  ok_actions         = [aws_sns_topic.ops.arn]
}


resource "aws_cloudwatch_dashboard" "dev" {
  dashboard_name = "event-dev-sg1"
  dashboard_body = jsonencode({
    widgets = [

      {
        "type" : "metric", "x" : 0, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Lambda Invocations (ingest vs worker)",
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", local.ingest_fn],
            [".", "Invocations", "FunctionName", local.worker_fn]
          ],
          "stat" : "Sum", "period" : 60, "region" : "ap-southeast-1", "view" : "timeSeries"
        }
      },
      {
        "type" : "metric", "x" : 12, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Lambda Errors & Throttles",
          "metrics" : [
            ["AWS/Lambda", "Errors", "FunctionName", local.ingest_fn],
            [".", "Errors", "FunctionName", local.worker_fn],
            [".", "Throttles", "FunctionName", local.ingest_fn],
            [".", "Throttles", "FunctionName", local.worker_fn]
          ],
          "stat" : "Sum", "period" : 60, "region" : "ap-southeast-1", "view" : "timeSeries"
        }
      },


      {
        "type" : "metric", "x" : 0, "y" : 6, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "SQS Oldest Message Age (s)",
          "metrics" : [
            ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", local.queue]
          ],
          "stat" : "Maximum", "period" : 60, "region" : "ap-southeast-1", "view" : "timeSeries"
        }
      },
      {
        "type" : "metric", "x" : 12, "y" : 6, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "SQS Messages Visible",
          "metrics" : [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", local.queue]
          ],
          "stat" : "Average", "period" : 60, "region" : "ap-southeast-1", "view" : "timeSeries"
        }
      }
    ]
  })
}
