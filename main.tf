# =========================
# S3 BUCKET
# =========================
resource "aws_s3_bucket" "bucket" {
  bucket = "terraform-order-bucket"
}

# =========================
# SQS QUEUE
# =========================
resource "aws_sqs_queue" "queue" {
  name = "terraform-order-queue"
}

# =========================
# SNS TOPIC
# =========================
resource "aws_sns_topic" "topic" {
  name = "terraform-order-notifications"
}

# =========================
# SECRET (SSM)
# =========================
resource "aws_ssm_parameter" "db_password" {
  name  = "/terraform-order/db_password"
  type  = "SecureString"
  value = "super-secret-password"
}

module "secret_test" {
  source        = "./modules/lambda_function"
  function_name = "terraform-secret-test"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role_arn      = data.aws_iam_role.lab_role.arn
  source_dir    = "${path.module}/functions/secret_test"

  environment_vars = {
    DB_PASSWORD = aws_ssm_parameter.db_password.name
  }
}

# =========================
# LAMBDA: INGEST
# =========================
module "order_ingest" {
  source        = "./modules/lambda_function"
  function_name = "terraform-order-ingest"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role_arn      = data.aws_iam_role.lab_role.arn
  source_dir    = "${path.module}/functions/order_ingest"

  environment_vars = {
    ORDER_BUCKET    = aws_s3_bucket.bucket.bucket
    ORDER_QUEUE_URL = aws_sqs_queue.queue.url
  }
}

# =========================
# LAMBDA: PROCESSOR
# =========================
module "order_processor" {
  source        = "./modules/lambda_function"
  function_name = "terraform-order-processor"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role_arn      = data.aws_iam_role.lab_role.arn
  source_dir    = "${path.module}/functions/order_processor"

  environment_vars = {
    ORDER_BUCKET     = aws_s3_bucket.bucket.bucket
    NOTIFY_TOPIC_ARN = aws_sns_topic.topic.arn
  }
}

# =========================
# LAMBDA: VALIDATOR
# =========================
module "order_validator" {
  source        = "./modules/lambda_function"
  function_name = "terraform-order-validator"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role_arn      = data.aws_iam_role.lab_role.arn
  source_dir    = "${path.module}/functions/order_validator"
}

# =========================
# SQS -> PROCESSOR TRIGGER
# =========================
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = module.order_processor.lambda_arn
  batch_size       = 1
}

# =========================
# STEP FUNCTIONS
# =========================
resource "aws_sfn_state_machine" "pipeline" {
  name     = "terraform-order-pipeline"
  role_arn = data.aws_iam_role.lab_role.arn

  definition = templatefile("${path.module}/step_function/definition.json", {
    validator_arn = module.order_validator.lambda_arn
    processor_arn = module.order_processor.lambda_arn
  })
}