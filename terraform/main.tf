terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "postgres" {
  name = "postgres:16"
}

resource "docker_volume" "postgres_data" {
  name = "terraform_postgres_data"
}

resource "docker_container" "postgres" {
  name  = "terraform_myapp_db"
  image = docker_image.postgres.image_id
  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}"
  ]
  ports {
    internal = 5432
    external = var.db_port
  }
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
}
