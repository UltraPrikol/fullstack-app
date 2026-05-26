terraform {
  required_version = ">= 1.0"
  
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
  
  backend "s3" {
    # Опционально: настройка бэкенда для хранения состояния в S3
    # bucket = "tfstate-bucket"
    # key    = "fullstack-app/terraform.tfstate"
    # region = "ru-central1"
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# ==================== СОЗДАНИЕ SERVICE ACCOUNT ====================
resource "yandex_iam_service_account" "book_api_sa" {
  name        = "book-api-sa-tf"
  description = "Service account for Book API (managed by Terraform)"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.book_api_sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.book_api_sa.id
  description        = "Static access key for CI/CD"
}

# ==================== CONTAINER REGISTRY ====================
resource "yandex_container_registry" "book_api_registry" {
  name      = "book-api-registry"
  folder_id = var.folder_id
}

# ==================== MANAGED POSTGRESQL ====================
resource "yandex_mdb_postgresql_cluster" "book_db" {
  name        = "book-db-cluster"
  environment = "PRODUCTION"
  network_id  = var.network_id
  
  config {
    version = 15
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id      = "network-ssd"
      disk_size         = 10
    }
    
    postgresql_config = {
      max_connections = 100
      shared_buffers  = 256
    }
  }
  
  host {
    zone      = var.zone
    name      = "book-db-host"
    subnet_id = var.subnet_id
    assign_public_ip = false
  }
  
  database {
    name = var.db_name
    owner = var.db_user
  }
  
  user {
    name     = var.db_user
    password = var.db_password
    permission {
      database_name = var.db_name
    }
  }
}

# ==================== SERVERLESS CONTAINER ====================
resource "yandex_serverless_container" "book_api" {
  name               = "book-api-container"
  memory             = 512
  execution_timeout  = "30s"
  concurrency        = 10
  service_account_id = yandex_iam_service_account.book_api_sa.id
  
  secrets {
    id = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
    version_id = "latest"
    key = "YC_SA_KEY"
    environment_variable = "YC_SA_KEY"
  }
  
  # Сначала создадим ресурс без ревизии, ревизия будет создана отдельно
  # Или можно добавить инициализационную ревизию
}

# ==================== ВЫХОДНЫЕ ДАННЫЕ ====================
output "service_account_id" {
  value = yandex_iam_service_account.book_api_sa.id
  sensitive = false
}

output "container_registry_id" {
  value = yandex_container_registry.book_api_registry.id
}

output "database_host" {
  value = yandex_mdb_postgresql_cluster.book_db.host[0].fqdn
  sensitive = true
}

output "container_url" {
  value = yandex_serverless_container.book_api.url
}