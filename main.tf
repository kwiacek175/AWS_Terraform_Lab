resource "aws_s3_bucket" "orders" {
  bucket = "orders-terraform-259378"
}

resource "aws_sqs_queue" "queue" {
  name = "order-queue-terraform-259378"
}

resource "aws_sns_topic" "topic" {
  name = "order-notifications-terraform-259378"
}

module "ingest" {
  source     = "./modules/lambda"
  name       = "order-ingest-terraform-259378"
  role       = data.aws_iam_role.lab_role.arn
  source_dir = "${path.module}/functions/ingest"
}

module "validator" {
  source     = "./modules/lambda"
  name       = "order-validator-terraform-259378"
  role       = data.aws_iam_role.lab_role.arn
  source_dir = "${path.module}/functions/validator"
}


module "processor" {
  source     = "./modules/lambda"
  name       = "order-processor-terraform-259378"
  role       = data.aws_iam_role.lab_role.arn
  source_dir = "${path.module}/functions/processor"
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/order-app/db_password"
  type  = "SecureString"
  value = "MySuperSecret123!"
}