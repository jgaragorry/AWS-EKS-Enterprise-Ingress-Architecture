# ------------------------------------------------------------------------------
# Lógica principal del recurso para vpc-network
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# ☁️ AWS VPC MODULE (Official)
# Best Practice: Usamos el módulo mantenido por la comunidad/AWS.
# ------------------------------------------------------------------------------

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  # Desplegar en 2 zonas de disponibilidad para Alta Disponibilidad (HA)
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  # NAT Gateways (Costo: $$$)
  # En Enterprise Real usamos enable_nat_gateway = true.
  # Para este LAB usaremos 'single_nat_gateway = true' para ahorrar dinero.
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # 🏷️ EKS TAGGING REQUIREMENTS (CRÍTICO)
  # Estos tags son obligatorios para que el Ingress Controller sepa dónde poner los balanceadores.
  
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1" # Dice: "Aquí van los Load Balancers Públicos"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1" # Dice: "Aquí van los Load Balancers Internos"
  }
}
