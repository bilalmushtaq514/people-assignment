aws_region   = "us-east-1"
project      = "people-assignment"
environment  = "dev"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

container_port = 5000
cpu            = 256
memory         = 512
desired_count  = 1

log_retention_days = 7
alarm_email        = ""
