output "db_container_name" {
  value = docker_container.postgres.name
}
output "db_connection_string" {
  value     = "postgresql://${var.db_user}:${var.db_password}@localhost:${var.db_port}/${var.db_name}"
  sensitive = true
}
