variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "secret_name" {
  description = "Name of the secret in Secrets Manager"
  type        = string
}

variable "secret_value" {
  description = "JSON-encoded secret value"
  type        = string
  sensitive   = true
}

variable "recovery_window_in_days" {
  description = "Number of days before a secret is fully deleted (0 for immediate, 7-30 for prod)"
  type        = number
  default     = 0
}
