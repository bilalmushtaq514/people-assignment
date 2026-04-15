locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.project}/${var.environment}/${var.secret_name}"
  recovery_window_in_days = var.recovery_window_in_days

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_value
}
