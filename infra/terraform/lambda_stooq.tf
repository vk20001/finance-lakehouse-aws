data "archive_file" "lambda_stooq_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/ingestion/lambda_equities_stooq"
  output_path = "${path.module}/../../src/ingestion/lambda_equities_stooq.zip"
}

resource "aws_lambda_function" "equities_stooq" {
  function_name    = "${var.project_prefix}-equities-stooq"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_stooq_zip.output_path
  source_code_hash = data.archive_file.lambda_stooq_zip.output_base64sha256
  timeout          = 20
  memory_size      = 256

  environment {
    variables = {
      RAW_BUCKET = aws_s3_bucket.raw.bucket
      RAW_PREFIX = "equities_stooq/"
      # Human->Stooq mapping, editable in console later if you want more
      SYMBOL_MAP = "AAPL:aapl.us,MSFT:msft.us,SPY:spy.us,JPM:jpm.us"
      INTERVAL   = "d"
    }
  }

  tags = {
    Project = var.project_prefix
    Owner   = var.owner
    Env     = "dev"
  }
}
