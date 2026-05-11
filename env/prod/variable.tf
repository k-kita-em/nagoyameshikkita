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
