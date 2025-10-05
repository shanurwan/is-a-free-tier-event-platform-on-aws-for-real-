terraform {
  backend "s3" {
    bucket         = "serverlesswan"
    key            = "event/dev/terraform.tfstate"
    region         = "ap-southeast-5"
    dynamodb_table = "serverless"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-southeast-1"
}
