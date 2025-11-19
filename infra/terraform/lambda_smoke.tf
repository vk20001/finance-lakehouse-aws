# Zip the lambda source
data "archive_file" "lambda_smoke_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/ingestion/lambda_smoke_write"
  output_path = "${path.module}/../../src/ingestion/lambda_smoke_write.zip"
}

resource "aws_lambda_function" "smoke_write" {
  function_name    = "${var.project_prefix}-smoke-write"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_smoke_zip.output_path
  source_code_hash = data.archive_file.lambda_smoke_zip.output_base64sha256
  timeout          = 10
  memory_size      = 128
  environment {
    variables = {
      RAW_BUCKET = aws_s3_bucket.raw.bucket
      RAW_PREFIX = "smoke_tests/"
    }
  }
  tags = {
    Project = var.project_prefix
    Owner   = var.owner
    Env     = "dev"
  }
}
