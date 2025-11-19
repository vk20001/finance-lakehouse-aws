# EventBridge → invoke Lambdas daily at 06:00/06:05 UTC (~07:00/07:05 CET)

# FRED @ 06:00 UTC
resource "aws_cloudwatch_event_rule" "fred_daily" {
  name                = "${var.project_prefix}-fred-daily"
  description         = "Daily FRED ingest (macro series)"
  schedule_expression = "cron(0 6 * * ? *)"
  tags                = { Project = var.project_prefix, Owner = var.owner, Env = "dev" }
}

resource "aws_cloudwatch_event_target" "fred_target" {
  rule      = aws_cloudwatch_event_rule.fred_daily.name
  target_id = "fred-lambda"
  arn       = aws_lambda_function.fred_macro_ingest.arn
}

resource "aws_lambda_permission" "fred_invoke_by_events" {
  statement_id  = "AllowEventBridgeInvokeFRED"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fred_macro_ingest.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.fred_daily.arn
}

# Stooq @ 06:05 UTC (staggered)
resource "aws_cloudwatch_event_rule" "stooq_daily" {
  name                = "${var.project_prefix}-stooq-daily"
  description         = "Daily Stooq equities ingest (OHLCV)"
  schedule_expression = "cron(5 6 * * ? *)"
  tags                = { Project = var.project_prefix, Owner = var.owner, Env = "dev" }
}

resource "aws_cloudwatch_event_target" "stooq_target" {
  rule      = aws_cloudwatch_event_rule.stooq_daily.name
  target_id = "stooq-lambda"
  arn       = aws_lambda_function.equities_stooq.arn
}

resource "aws_lambda_permission" "stooq_invoke_by_events" {
  statement_id  = "AllowEventBridgeInvokeSTOOQ"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.equities_stooq.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stooq_daily.arn
}
