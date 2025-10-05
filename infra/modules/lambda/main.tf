variable "name" {
  type = string
}

variable "handler" {
  type = string
}

variable "runtime" {
  type    = string
  default = "python3.11"
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "timeout" {
  type    = number
  default = 10
}

variable "env" {
  type    = map(string)
  default = {}
}

variable "zip_path" {
  type    = string
  default = ""
}

variable "create_function_url" {
  type    = bool
  default = false
}

variable "url_auth_type" {
  type    = string
  default = "NONE" # or "AWS_IAM"
}



variable "policy_statements" {
  description = "List of {actions=[...], resources=[...], effect=optional('Allow')}"
  type        = list(object({
    actions   = list(string)
    resources = list(string)
    effect    = optional(string)
  }))
  default = []
}


data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Build an inline policy doc from the caller-provided statements
data "aws_iam_policy_document" "inline" {
  dynamic "statement" {
    for_each = var.policy_statements
    content {
      actions   = statement.value.actions
      resources = statement.value.resources
      effect    = coalesce(try(statement.value.effect, null), "Allow")
    }
  }
}

resource "aws_iam_policy" "extra" {
  count  = length(var.policy_statements) > 0 ? 1 : 0
  name   = "${var.name}-extra"
  policy = data.aws_iam_policy_document.inline.json
}

resource "aws_iam_role_policy_attachment" "attach_extra" {
  count      = length(var.policy_statements) > 0 ? 1 : 0
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.extra[0].arn
}


resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "fn" {
  function_name = var.name
  role          = aws_iam_role.role.arn
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout

  filename         = var.zip_path
  source_code_hash = filebase64sha256(var.zip_path)

  environment {
    variables = var.env
  }
}

resource "aws_lambda_function_url" "url" {
  count              = var.create_function_url ? 1 : 0
  function_name      = aws_lambda_function.fn.function_name
  authorization_type = var.url_auth_type
}


output "function_name" {
  value = aws_lambda_function.fn.function_name
}

output "function_url" {
  value = try(aws_lambda_function_url.url[0].function_url, null)
}
