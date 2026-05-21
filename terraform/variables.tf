variable "db_name"     { default = "myapp" }
variable "db_user"     { default = "dev" }
variable "db_password" { default = "secret"; sensitive = true }
variable "db_port"     { default = 5433 }
