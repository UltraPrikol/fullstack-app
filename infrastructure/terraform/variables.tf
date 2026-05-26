variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = true
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  sensitive   = true
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "network_id" {
  description = "Network ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "bookdb"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "bookuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}