# ---------- Networking ----------

module "vpc" {
  source = "../../modules/vpc"

  project              = var.project
  environment          = var.environment
  cidr_block           = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = true
  single_nat_gateway   = true
}

# ---------- Container Registry ----------

module "ecr" {
  source = "../../modules/ecr"

  project         = var.project
  environment     = var.environment
  repository_name = "${var.project}-${var.environment}"
  scan_on_push    = true
  max_image_count = 15
}

# ---------- Security ----------

module "security_groups" {
  source = "../../modules/security-groups"

  project        = var.project
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port
}

module "secrets" {
  source = "../../modules/secrets"

  project                 = var.project
  environment             = var.environment
  secret_name             = "app-config"
  secret_value            = var.app_secret_value
  recovery_window_in_days = 7
}

module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment
  secrets_arn = module.secrets.secret_arn
}

# ---------- Load Balancer ----------

module "alb" {
  source = "../../modules/alb"

  project             = var.project
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  security_group_id   = module.security_groups.alb_security_group_id
  container_port      = var.container_port
  health_check_path   = "/health"
  acm_certificate_arn = var.acm_certificate_arn
}

# ---------- Monitoring ----------

module "monitoring" {
  source = "../../modules/monitoring"

  project                 = var.project
  environment             = var.environment
  aws_region              = var.aws_region
  ecs_cluster_name        = "${var.project}-${var.environment}-cluster"
  ecs_service_name        = "${var.project}-${var.environment}-service"
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  log_retention_days      = var.log_retention_days
  alarm_email             = var.alarm_email
  cpu_threshold           = 80
  error_threshold         = 10
  response_time_threshold = 2
}

# ---------- ECS Fargate ----------

module "ecs" {
  source = "../../modules/ecs"

  project            = var.project
  environment        = var.environment
  aws_region         = var.aws_region
  cluster_name       = "${var.project}-${var.environment}-cluster"
  task_family        = "${var.project}-${var.environment}"
  container_name     = "${var.project}-app"
  container_image    = "${module.ecr.repository_url}:${var.container_image_tag}"
  container_port     = var.container_port
  cpu                = var.cpu
  memory             = var.memory
  desired_count      = var.desired_count
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security_groups.ecs_security_group_id
  target_group_arn   = module.alb.target_group_arn
  log_group_name     = module.monitoring.log_group_name
  secrets_arn        = module.secrets.secret_arn
}
