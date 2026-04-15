variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster (for CloudWatch dimensions)"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service (for CloudWatch dimensions)"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (for CloudWatch dimensions)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group (for CloudWatch dimensions)"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "alarm_email" {
  description = "Email address to receive alarm notifications (leave empty to skip SNS)"
  type        = string
  default     = ""
}

variable "cpu_threshold" {
  description = "CPU utilization percentage to trigger alarm"
  type        = number
  default     = 80
}

variable "error_threshold" {
  description = "Number of 5xx errors in the evaluation period to trigger alarm"
  type        = number
  default     = 10
}

variable "response_time_threshold" {
  description = "Target response time in seconds to trigger alarm"
  type        = number
  default     = 2
}

variable "aws_region" {
  description = "AWS region (for dashboard links)"
  type        = string
}
