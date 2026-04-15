aws_region   = "us-east-1"
project      = "people-assignment"
environment  = "prod"

vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

container_port = 5000
cpu            = 1024
memory         = 2048
desired_count  = 3

log_retention_days = 90
alarm_email        = ""
