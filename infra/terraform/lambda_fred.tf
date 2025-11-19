# Zip the FRED lambda source
data "archive_file" "lambda_fred_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/ingestion/lambda_fred_macro"
  output_path = "${path.module}/../../src/ingestion/lambda_fred_macro.zip"
}

resource "aws_lambda_function" "fred_macro_ingest" {
  function_name    = "${var.project_prefix}-fred-macro"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_fred_zip.output_path
  source_code_hash = data.archive_file.lambda_fred_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      RAW_BUCKET    = aws_s3_bucket.raw.bucket
      RAW_PREFIX    = "fred/"
      FRED_API_KEY  = "" # <-- fill after first apply or override via console
      FRED_SERIES   = "DGS10,TB3MS,CPIAUCSL,UNRATE"
      FRED_BASE_URL = "https://api.stlouisfed.org/fred/series/observations"
    }
  }

  tags = {
    Project = var.project_prefix
    Owner   = var.owner
    Env     = "dev"
  }
}
