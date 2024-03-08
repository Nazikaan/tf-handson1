terraform {
  backend "s3" {
    region         = "us-east-1"
    bucket         = "hw1-terraform"
    key            = "3"
    dynamodb_table = "terraform-state-lock-dynamo"
  }
}
