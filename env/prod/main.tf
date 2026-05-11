provider "aws" {
  region = "ap-northeast-1"
}

module "prod_vpc" {
  source      = "../../modules/vpc"
  project_env = var.project_env
}

resource "aws_secretsmanager_secret" "app_key" {
  name                    = "${var.project_env}-app-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_key" {
  secret_id     = aws_secretsmanager_secret.app_key.id
  secret_string = var.app_key
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_env}-db-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

module "prod_ecs" {
  source          = "../../modules/ecs"
  vpc_id          = module.prod_vpc.vpc_id
  ecs_subnet1a    = module.prod_vpc.ecs_subnet1a
  ecs_subnet1c    = module.prod_vpc.ecs_subnet1c
  ecr_image_url   = "040591922141.dkr.ecr.ap-northeast-1.amazonaws.com/my-repository:latest"
  project_env     = var.project_env
  public_subnet1a = module.prod_vpc.public_subnet1a
  public_subnet1c = module.prod_vpc.public_subnet1c
  db_host         = var.db_host
  db_username     = "root"
  app_key_secret_arn     = aws_secretsmanager_secret.app_key.arn
  db_password_secret_arn = aws_secretsmanager_secret.db_password.arn
  desired_count          = 1
  app_url                = "https://dywrxp7cm24bg.cloudfront.net"
}

module "prod_cicd" {
  source             = "../../modules/cicd"
  project_env        = var.project_env
  ecr_repository_url = "040591922141.dkr.ecr.ap-northeast-1.amazonaws.com/my-repository"
  github_repo        = var.github_repo
  subnet_id_1        = module.prod_vpc.ecs_subnet1a
  subnet_id_2        = module.prod_vpc.ecs_subnet1c
  security_group_id  = module.prod_ecs.ecs_security_group
}

module "prod_rds" {
  source             = "../../modules/storage"
  project_env        = var.project_env
  vpc_id             = module.prod_vpc.vpc_id
  db_subnet1a        = module.prod_vpc.db_subnet1a
  db_subnet1c        = module.prod_vpc.db_subnet1c
  ecs_security_group = module.prod_ecs.ecs_security_group
  db_username        = "root"
  db_password        = var.db_password
  multi_az           = false
  instance_class     = "db.t3.micro"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-statefile-kk-samurainagoyameshi-prod"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

terraform {
  backend "s3" {
    bucket  = "terraform-statefile-kk-samurainagoyameshi-prod"
    region  = "ap-northeast-1"
    key     = "prod-tfstate/terraform.tfstate"
    encrypt = true
  }
}
