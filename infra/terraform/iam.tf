# Execution role that Lambda will assume
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_prefix}-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = {
    Project = var.project_prefix
    Owner   = var.owner
    Env     = "dev"
  }
}

# Minimal permissions: write to RAW bucket + CloudWatch logs
data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    sid     = "S3WriteRaw"
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:PutObjectAcl", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.raw.arn,
      "${aws_s3_bucket.raw.arn}/*"
    ]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:*:log-group:/aws/lambda/*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${var.project_prefix}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
