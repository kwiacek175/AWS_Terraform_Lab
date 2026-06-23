terraform {
  backend "s3" {
    bucket         = "terraform-order-state-bucket"
    key            = "terraform-order/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-order-locks"
    encrypt        = true
  }
}