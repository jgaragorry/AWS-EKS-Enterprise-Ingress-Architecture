# ------------------------------------------------------------------------------
# Definición de variables de entrada para vpc-network
# ------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}
