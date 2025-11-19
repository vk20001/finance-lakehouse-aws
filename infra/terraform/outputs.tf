output "raw_bucket" { value = aws_s3_bucket.raw.bucket }
output "clean_bucket" { value = aws_s3_bucket.clean.bucket }
output "gold_bucket" { value = aws_s3_bucket.gold.bucket }
