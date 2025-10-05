## Prerequisite
1. Remote Terraform state (S3) with locking (DynamoDB)

S3 bucket holds the state file, DynamoDB table prevents two applies at once (locking).

2. AWS OIDC deploy role (no long-lived keys)

This is for our CI/CD authentication to automate terraform later 

3. Set a budget alert, a Free Tier alert, and plan to keep log retention short (7 days)

Prevent bill shock and log bloat while you learn. 


## Repo Layout

1. Folder Structure with placeholder



## Module (small, focused Terraform units)

1. SQS

2. Dynamodb

main.tf

```
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

```

## live/dev/ (composition” layer that instantiates modules for the dev env)

## services/ (code to package into zip files for Lambda later.)
 
## Github ACtion

