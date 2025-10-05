variable "name" {}
variable "receive_wait_time_seconds" { default = 20 }
variable "message_retention_seconds" { default = 1209600 } # 14d

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "main" {
  name                      = var.name
  receive_wait_time_seconds = var.receive_wait_time_seconds
  message_retention_seconds = var.message_retention_seconds
  redrive_policy            = jsonencode({ deadLetterTargetArn = aws_sqs_queue.dlq.arn, maxReceiveCount = 5 })
  sqs_managed_sse_enabled   = true
}

output "queue_url" { value = aws_sqs_queue.main.id }
output "queue_arn" { value = aws_sqs_queue.main.arn }
output "dlq_arn"   { value = aws_sqs_queue.dlq.arn }
