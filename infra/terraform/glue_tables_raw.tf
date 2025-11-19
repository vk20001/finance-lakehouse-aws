locals {
  raw_fred_path  = "s3://${aws_s3_bucket.raw.bucket}/fred/"
  raw_stooq_path = "s3://${aws_s3_bucket.raw.bucket}/equities_stooq/"
}

# =========================
# FRED RAW (JSON)
# =========================
resource "aws_glue_catalog_table" "fred_raw" {
  name          = "fred_raw"
  database_name = aws_glue_catalog_database.db_finance.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
    "EXTERNAL"       = "TRUE"

    "projection.enabled"       = "true"
    "projection.series.type"   = "enum"
    "projection.series.values" = "DGS10,TB3MS,CPIAUCSL,UNRATE"
    "projection.year.type"     = "integer"
    "projection.year.range"    = "2015,2100"
    "projection.month.type"    = "integer"
    "projection.month.range"   = "1,12"
    "projection.month.digits"  = "2"
    "projection.day.type"      = "integer"
    "projection.day.range"     = "1,31"
    "projection.day.digits"    = "2"

    # Glue must expand $${...}; Terraform must NOT.
    "storage.location.template" = "${local.raw_fred_path}series=$${series}/year=$${year}/month=$${month}/day=$${day}/"
  }

  partition_keys {
    name = "series"
    type = "string"
  }
  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }

  storage_descriptor {
    location      = local.raw_fred_path
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "json"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters            = { "ignore.malformed.json" = "true" }
    }

    columns {
      name = "realtime_start"
      type = "string"
    }
    columns {
      name = "realtime_end"
      type = "string"
    }
    columns {
      name = "observation_start"
      type = "string"
    }
    columns {
      name = "observation_end"
      type = "string"
    }
    columns {
      name = "observations"
      type = "array<struct<realtime_start:string,realtime_end:string,date:string,value:string>>"
    }
  }
}

# =========================
# STOOQ RAW (CSV) — keep all STRING in RAW
# =========================
resource "aws_glue_catalog_table" "stooq_raw" {
  name          = "equities_stooq_raw"
  database_name = aws_glue_catalog_database.db_finance.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"         = "csv"
    "EXTERNAL"               = "TRUE"
    "skip.header.line.count" = "1"

    "projection.enabled"       = "true"
    "projection.symbol.type"   = "enum"
    "projection.symbol.values" = "AAPL,MSFT,SPY,JPM"
    "projection.year.type"     = "integer"
    "projection.year.range"    = "2010,2100"
    "projection.month.type"    = "integer"
    "projection.month.range"   = "1,12"
    "projection.month.digits"  = "2"
    "projection.day.type"      = "integer"
    "projection.day.range"     = "1,31"
    "projection.day.digits"    = "2"

    "storage.location.template" = "${local.raw_stooq_path}symbol=$${symbol}/year=$${year}/month=$${month}/day=$${day}/"
  }

  partition_keys {
    name = "symbol"
    type = "string"
  }
  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }

  storage_descriptor {
    location      = local.raw_stooq_path
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "OpenCSVSerde"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "\""
        "escapeChar"    = "\\"
      }
    }

    columns {
      name = "date"
      type = "string"
    }
    columns {
      name = "open"
      type = "string"
    }
    columns {
      name = "high"
      type = "string"
    }
    columns {
      name = "low"
      type = "string"
    }
    columns {
      name = "close"
      type = "string"
    }
    columns {
      name = "volume"
      type = "string"
    }
  }
}
