data "archive_file" "zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/${var.name}.zip"
}

resource "aws_lambda_function" "this" {
  function_name = var.name
  role          = var.role
  runtime       = "python3.11"
  handler       = "handler.lambda_handler"
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
}