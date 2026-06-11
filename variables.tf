variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = ""
  type        = string
  default     = "aulas"
}

variable "environment" {
  description = ""
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = ""
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = ""
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_password" {
  description = "senha RDS PostgreSQL"
  type        = string
  sensitive   = true
}
