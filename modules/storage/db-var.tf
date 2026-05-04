variable "project_env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnet1a" {
  type = string
}

variable "db_subnet1c" {
  type = string
}

variable "ecs_security_group" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}
