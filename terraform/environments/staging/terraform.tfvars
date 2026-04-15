aws_region   = "us-east-1"
project      = "people-assignment"
environment  = "staging"

vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

container_port = 5000
cpu            = 512
memory         = 1024
desired_count  = 2

log_retention_days = 30
alarm_email        = ""
