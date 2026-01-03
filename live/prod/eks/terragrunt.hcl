# ------------------------------------------------------------------------------
# Instanciación del módulo EKS para PROD (Depende de VPC)
# ------------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/eks-cluster"
}

# 🔗 DEPENDENCIA: Leer outputs del módulo VPC
# Esto hace que EKS espere a que la VPC exista antes de intentar crearse.
dependency "vpc" {
  config_path = "../vpc"
  
  # Usamos mocks para que comandos como 'validate' no fallen si la VPC no existe aún
  mock_outputs = {
    vpc_id          = "vpc-fake-id"
    private_subnets = ["subnet-fake-1", "subnet-fake-2"]
  }
}

inputs = {
  project_name    = "eks-enterprise"
  cluster_name    = "eks-enterprise-prod"
  environment     = "prod"
  cluster_version = "1.29"

  # 👇 Aquí inyectamos los valores reales que vienen de la VPC
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets
}
