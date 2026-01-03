# ------------------------------------------------------------------------------
# Instanciación del módulo VPC para PROD
# ------------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/vpc-network"
}

inputs = {
  project_name = "eks-enterprise"
  environment  = "prod"
  vpc_cidr     = "10.0.0.0/16"
}
