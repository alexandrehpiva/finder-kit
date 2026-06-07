variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_owner" {
  type    = string
  default = "alexandrehpiva"
}

variable "github_repo" {
  type    = string
  default = "finder-kit"
}

variable "bucket_name" {
  type        = string
  description = "Nome globalmente único do bucket S3"
  default     = "alexandrehpiva-finder-kit-releases"
}

variable "object_expiration_days" {
  type        = number
  description = "Expira artefatos antigos para controlar custo (0 = desligado)"
  default     = 0
}
