locals {
  athena_output_prefix = "athena/query_results/"
}

# Athena Workgroup with a bytes-scan cap (FinOps guardrail)
resource "aws_athena_workgroup" "wg_finance" {
  name = "${var.project_prefix}-wg"

  configuration {
    enforce_workgroup_configuration = true
    # Cap each query to 200 MB scanned (raise later if needed)
    bytes_scanned_cutoff_per_query = 200000000

    result_configuration {
      output_location = "s3://${aws_s3_bucket.clean.bucket}/${local.athena_output_prefix}"
    }
  }

  tags = {
    Project = var.project_prefix
    Owner   = var.owner
    Env     = "dev"
  }
}

# Glue Data Catalog database for our lakehouse
resource "aws_glue_catalog_database" "db_finance" {
  name        = "${var.project_prefix}_db"
  description = "Finance lakehouse database (raw/clean/gold) for Athena"
}
