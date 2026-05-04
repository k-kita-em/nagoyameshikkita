variable "project_env" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "container_name" {
  type    = string
  default = "app"
}

variable "subnet_id_1" {
  type = string
}

variable "subnet_id_2" {
  type = string
}

variable "security_group_id" {
  type = string
}
