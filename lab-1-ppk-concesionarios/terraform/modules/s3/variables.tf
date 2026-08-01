variable "bucket_name_prefix" {
  description = "Prefix for the company data bucket name (a random suffix is appended for global uniqueness)."
  type        = string
  default     = "ppk-company-data"
}
