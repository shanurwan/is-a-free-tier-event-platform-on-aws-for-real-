module "queue" {
  source                    = "../../modules/sqs"
  name                      = "eventq-dev-sg1"
  receive_wait_time_seconds = 20
}

module "table" {
  source = "../../modules/dynamodb"
  name   = "events-dev-sg1"
}

module "bucket" {
  source = "../../modules/s3"
  name   = "eventserverlesswansg1"
}


module "ingest" {
  source              = "../../modules/lambda"
  name                = "ingest-dev-sg1" # ← change from ingest-dev
  handler             = "app.handler"
  runtime             = "python3.11"
  zip_path            = "${path.module}/../../../services/ingest_lambda/ingest.zip"
  create_function_url = true # stays true in -1
  url_auth_type       = "NONE"
  env                 = { QUEUE_URL = module.queue.queue_url }
  policy_statements = [
    { actions = ["sqs:SendMessage"], resources = [module.queue.queue_arn] }
  ]
}

module "worker" {
  source   = "../../modules/lambda"
  name     = "worker-dev-sg1" # ← change from worker-dev
  handler  = "app.handler"
  runtime  = "python3.11"
  zip_path = "${path.module}/../../../services/worker_lambda/worker.zip"
  env = {
    TABLE_NAME = module.table.name
    BUCKET     = module.bucket.name
  }
  policy_statements = [
    {
      actions   = ["dynamodb:PutItem", "dynamodb:DescribeTable"]
      resources = ["arn:aws:dynamodb:*:*:table/${module.table.name}"]
    },
    {
      actions   = ["s3:PutObject"]
      resources = ["arn:aws:s3:::${module.bucket.name}/*"]
    },
    {
      actions = [
        "sqs:ReceiveMessage", "sqs:DeleteMessage",
        "sqs:ChangeMessageVisibility", "sqs:GetQueueAttributes", "sqs:GetQueueUrl"
      ]
      resources = [module.queue.queue_arn]
    }
  ]
}


resource "aws_lambda_event_source_mapping" "worker_from_sqs" {
  event_source_arn = module.queue.queue_arn
  function_name    = module.worker.function_name
  batch_size       = 10
}


output "ingest_url" { value = module.ingest.function_url }
output "queue_url" { value = module.queue.queue_url }
output "table_name" { value = module.table.name }
output "bucket_name" { value = module.bucket.name }
