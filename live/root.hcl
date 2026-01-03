# ==============================================================================
# 🧠 LIVE/ROOT.HCL
# DESCRIPCIÓN: Configuración Padre. S3 Native Locking activado.
# ==============================================================================

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # 👇 Reemplaza con el output de 00_init_backend.sh
    bucket       = "eks-enterprise-ingress-state-533267117128"
    
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    
    # 🔥 S3 NATIVE LOCKING (Terraform 1.10+)
    # Ya no usamos dynamodb_table.
    use_lockfile = true
  }
}

# Generar Provider AWS con restricción de versión
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
  required_version = ">= 1.10"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project     = "AWS-EKS-Enterprise-Ingress"
      ManagedBy   = "Terragrunt"
      Environment = "Prod"
    }
  }
}
EOF
}
