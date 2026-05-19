
provider "aws" {
    region = "ap-northeast-1"
  
}

module "dev_vpc" {
    source = "../../modules/vpc"
    project_env = var.project_env
    # ecs_security_group_id = module.ecs.ecs_security_group_id
  
}
resource "aws_secretsmanager_secret" "app_key" {
  name = "${var.project_env}-app-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_key" {
  secret_id     = aws_secretsmanager_secret.app_key.id
  secret_string = var.app_key
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_env}-db-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

module "dev_ecs" {
  source          = "../../modules/ecs"
  vpc_id          = module.dev_vpc.vpc_id
  ecs_subnet1a    = module.dev_vpc.ecs_subnet1a
  ecs_subnet1c    = module.dev_vpc.ecs_subnet1c
  ecr_image_url   = "040591922141.dkr.ecr.ap-northeast-1.amazonaws.com/nagoyameshi-dev-ecr:latest"
  project_env     = var.project_env
  public_subnet1a = module.dev_vpc.public_subnet1a
  public_subnet1c = module.dev_vpc.public_subnet1c
  db_host         = var.db_host
  db_username     = "root"
  app_key_secret_arn     = aws_secretsmanager_secret.app_key.arn
  db_password_secret_arn = aws_secretsmanager_secret.db_password.arn
  desired_count          = 1
  app_url                = "https://d2jriozcuyz3ue.cloudfront.net"
}

module "dev_cicd" {
  source             = "../../modules/cicd"
  project_env        = var.project_env
  ecr_repository_url = "040591922141.dkr.ecr.ap-northeast-1.amazonaws.com/nagoyameshi-dev-ecr"
  github_repo        = var.github_repo
  subnet_id_1        = module.dev_vpc.ecs_subnet1a
  subnet_id_2        = module.dev_vpc.ecs_subnet1c
  security_group_id  = module.dev_ecs.ecs_security_group
  github_branch      = "dev"
}

module "dev_rds" {
  source = "../../modules/storage"
  project_env = var.project_env
  vpc_id = module.dev_vpc.vpc_id
  db_subnet1a = module.dev_vpc.db_subnet1a
  db_subnet1c = module.dev_vpc.db_subnet1c
  ecs_security_group = module.dev_ecs.ecs_security_group
  db_username = "root"
  db_password = var.db_password
  
}



#バケットの作成
resource "aws_s3_bucket" "terraform_state" {
  bucket = "nagoyameshi-dev-s3-tfstate-040591922141"
}
resource "aws_s3_bucket_versioning" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
#statefileの保存先（S3バケット作成後に有効化する）
terraform {
  backend "s3" {
    bucket  = "nagoyameshi-dev-s3-tfstate-040591922141"
    region  = "ap-northeast-1"
    key     = "dev-tfstate/terraform.tfstate"
    encrypt = true
  }
}