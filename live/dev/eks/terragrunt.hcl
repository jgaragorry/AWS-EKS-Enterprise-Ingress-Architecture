# ------------------------------------------------------------------------------
# Instanciación del módulo EKS para DEV (Depende de VPC)
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
  cluster_name    = "eks-enterprise-dev"
  environment     = "dev"
  cluster_version = "1.29"

  # 👇 SOBRESCRIBIR TAMAÑO PARA AHORRAR $$$
  instance_types = ["t3.small"]   # Más barato que medium
  min_size       = 1
  max_size       = 2
  desired_size   = 1              # Solo 1 nodo (Suficiente para pruebas)

  # Valores de red
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets
}
