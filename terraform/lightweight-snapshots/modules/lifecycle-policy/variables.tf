variable "bucket_name" {
  type        = string
  description = "The name of the bucket to attach the lifecycle policy to."
}

variable "expiration_timeframe" {
  type        = number
  default     = 10
  description = "The number of days to keep the objects before expiration."
}

variable "path_prefix" {
  type        = string
  default     = "minimal/"
  description = "The path prefix to apply the lifecycle policy to."
}

variable "rule_id" {
  type        = string
  default     = "obselete-snapshots"
  description = "The ID of the lifecycle rule."
}

variable "status" {
  type        = string
  default     = "Enabled"
  description = "The status of the lifecycle rule."
}
