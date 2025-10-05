variable "name" {
  type = string
}
variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

resource "aws_dynamodb_table" "this" {
  name         = var.name
  billing_mode = var.billing_mode

  hash_key = "pk"
  attribute {
    name = "pk"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}

output "name" {
  value = aws_dynamodb_table.this.name
}
