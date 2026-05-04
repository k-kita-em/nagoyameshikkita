variable "project_env" {
  type = string
}

variable "app_key" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_host" {
  type    = string
  default = ""
}

variable "github_repo" {
  type = string
}
# variable "ecs_subnet1a" {
#     type = string
  
# }
# variable "vpc_id" {
#     type = string
  
# }
# variable "alb_security_group" {
#     type = string
  
# }
# variable "ecs_security_group_id" {
#     type = string
  
# }