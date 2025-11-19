data "archive_file" "lambda_yahoo_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/ingestion/lambda_yahoo_equities"
  output_path = "${path.module}/../../src/ingestion/lambda_yahoo_equities.zip"
}

resource "aws_lambda_function" "yahoo_equities" {
  function_name    = "${var.project_prefix}-yahoo-equities"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_yahoo_zip.output_path
  source_code_hash = data.archive_file.lambda_yahoo_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      RAW_BUCKET = aws_s3_bucket.raw.bucket
      RAW_PREFIX = "yahoo_equities/"
      TICKERS    = "AAPL,MSFT,SPY,JPM,^GSPC"
      RANGE      = "5y"
      INTERVAL   = "1d"
    }
  }

  tags = {
    Project = var.project_prefix
    Owner   = var.owner
    Env     = "dev"
  }
}
