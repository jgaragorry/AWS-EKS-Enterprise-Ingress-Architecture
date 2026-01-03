# ------------------------------------------------------------------------------
# Instanciación del módulo VPC para el entorno DEV
# ------------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  # Apuntamos al mismo módulo maestro que PROD (Reutilización de código)
  source = "../../../modules/vpc-network"
}

inputs = {
  # 🆔 Identificadores únicos para DEV
  project_name = "eks-enterprise"
  vpc_name     = "vpc-enterprise-dev"  # Nombre claro para identificarlo en AWS Console
  environment  = "dev"                 # Tag clave para filtrar recursos y costos

  # 🌐 Configuración de Red
  # Definimos explícitamente el CIDR. 
  # Nota: Al ser entornos aislados, podemos reusar 10.0.0.0/16 sin conflictos.
  vpc_cidr     = "10.0.0.0/16"
}
