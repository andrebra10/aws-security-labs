variable "project_name" {
  description = "Prefix used to name CloudTrail/GuardDuty resources."
  type        = string
}

variable "enable_guardduty" {
  description = "Whether to enable a GuardDuty detector for the account/region."
  type        = bool
  default     = true
}
