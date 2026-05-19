resource "aws_db_subnet_group" "db" {
  name       = "${var.project_env}-db-subnet-group"
  subnet_ids = [var.db_subnet1a, var.db_subnet1c]

  tags = {
    Name = "${var.project_env}-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_env}-rds-sg"
  description = "Security Group for RDS"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_env}-rds-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id             = aws_security_group.rds.id
  referenced_security_group_id  = var.ecs_security_group
  from_port                     = 3306
  to_port                       = 3306
  ip_protocol                   = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_db_parameter_group" "mysql" {
  name   = "${var.project_env}-mysql-pg"
  family = "mysql8.0"

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }
}

resource "aws_db_instance" "mysql" {
  identifier              = "${var.project_env}-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.instance_class
  allocated_storage       = 20

  db_name                 = "laravel_nagoyameshi"
  username                = var.db_username
  password                = var.db_password

  db_subnet_group_name    = aws_db_subnet_group.db.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  parameter_group_name    = aws_db_parameter_group.mysql.name

  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = var.multi_az

  backup_retention_period = 1 #バックアップ保持日数 本当は7にしたいけど無料枠のため1
  backup_window           = "18:00-19:00" #バックアップ実行時間

  tags = {
    Name = "${var.project_env}-mysql"
  }
}
