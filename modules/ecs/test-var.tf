variable "project_env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ecs_subnet1a" {
  type = string
}

variable "ecs_subnet1c" {
  type = string
}

# variable "ecs_security_group" {
#   type = string
# }

# variable "alb_arn" {
#   type = string
# }

variable "ecr_image_url" {
  type = string
}

variable "public_subnet1a" {
  type = string
  
}

variable "public_subnet1c" {
  type = string
}

variable "db_host" {
  type    = string
  default = ""
}

variable "db_name" {
  type    = string
  default = "laravel_nagoyameshi"
}

variable "db_username" {
  type = string
}

variable "app_key_secret_arn" {
  type = string
}

variable "db_password_secret_arn" {
  type = string
}
