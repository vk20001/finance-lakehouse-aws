variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "project_prefix" {
  type    = string
  default = "finance-lake"
}

variable "owner" {
  type    = string
  default = "vaishnavi"
}

variable "bucket_suffix" {
  type        = string
  description = "unique suffix for bucket names (e.g., your initials + random)"
}
