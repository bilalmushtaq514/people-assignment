variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "secrets_arn" {
  description = "ARN of the Secrets Manager secret to grant read access"
  type        = string
}
