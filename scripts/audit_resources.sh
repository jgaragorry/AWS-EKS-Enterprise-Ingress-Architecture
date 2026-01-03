# ------------------------------------------------------------------------------
# AUDITORIA EXHAUSTIVA: Busca EKS, ELB, ENI, EBS, NAT GWs huérfanos
# ------------------------------------------------------------------------------

#!/bin/bash

# ==============================================================================
# 🕵️‍♂️ AUDITORIA FINOPS - AWS CLEANUP CHECK
# Autor: Jorge Garagorry | Geek Monkey Tech
# Descripción: Verifica que no queden recursos huérfanos cobrando en la cuenta.
# Región: us-east-1
# ==============================================================================

# Colores para output visual
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REGION="us-east-1"
PROFILE="default" # Cambiar si usas un perfil específico de AWS CLI

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}   INICIANDO AUDITORÍA DE RECURSOS EN: $REGION       ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Función auxiliar para imprimir estado
check_status() {
    local RESOURCE_NAME=$1
    local COUNT=$2
    local DETAILS=$3

    if [ "$COUNT" -eq 0 ]; then
        echo -e "${GREEN}[✔] $RESOURCE_NAME: Limpio (0 encontrados)${NC}"
    else
        echo -e "${RED}[✖] $RESOURCE_NAME: ALERTA - $COUNT ENCONTRADOS${NC}"
        echo -e "${YELLOW}    -> IDs: $DETAILS${NC}"
    fi
}

# ---------------------------------------------------
# 1. CLÚSTERES EKS
# ---------------------------------------------------
echo -e "\n🔍 Verificando Contenedores (EKS)..."
EKS_CLUSTERS=$(aws eks list-clusters --region $REGION --query 'clusters[*]' --output text)
EKS_COUNT=$(echo "$EKS_CLUSTERS" | wc -w)
# Ajuste: wc -w devuelve 0 si la cadena está vacía, pero a veces devuelve 1 línea vacía.
if [ -z "$EKS_CLUSTERS" ]; then EKS_COUNT=0; fi
check_status "EKS Clusters" "$EKS_COUNT" "$EKS_CLUSTERS"

# ---------------------------------------------------
# 2. COMPUTO (EC2 & ASG)
# ---------------------------------------------------
echo -e "\n🔍 Verificando Cómputo (EC2)..."

# Instancias (Running o Stopped - ambas cobran almacenamiento, running cobra computo)
INSTANCES=$(aws ec2 describe-instances --region $REGION \
    --filters "Name=instance-state-name,Values=running,stopped,pending" \
    --query 'Reservations[*].Instances[*].InstanceId' --output text)
if [ -z "$INSTANCES" ]; then INST_COUNT=0; else INST_COUNT=$(echo "$INSTANCES" | wc -w); fi
check_status "EC2 Instances (Activas/Detenidas)" "$INST_COUNT" "$INSTANCES"

# Auto Scaling Groups
ASGS=$(aws autoscaling describe-auto-scaling-groups --region $REGION --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text)
if [ -z "$ASGS" ]; then ASG_COUNT=0; else ASG_COUNT=$(echo "$ASGS" | wc -w); fi
check_status "Auto Scaling Groups" "$ASG_COUNT" "$ASGS"

# ---------------------------------------------------
# 3. RED Y CONECTIVIDAD (NAT GW es el más caro)
# ---------------------------------------------------
echo -e "\n🔍 Verificando Red (Costos Altos)..."

# NAT Gateways (Solo estado 'available' cobra)
NATS=$(aws ec2 describe-nat-gateways --region $REGION \
    --filter "Name=state,Values=available" \
    --query 'NatGateways[*].NatGatewayId' --output text)
if [ -z "$NATS" ]; then NAT_COUNT=0; else NAT_COUNT=$(echo "$NATS" | wc -w); fi
check_status "NAT Gateways (Activos)" "$NAT_COUNT" "$NATS"

# Elastic IPs (Cobran si no están adjuntas a una instancia corriendo)
EIPS=$(aws ec2 describe-addresses --region $REGION --query 'Addresses[*].PublicIp' --output text)
if [ -z "$EIPS" ]; then EIP_COUNT=0; else EIP_COUNT=$(echo "$EIPS" | wc -w); fi
check_status "Elastic IPs" "$EIP_COUNT" "$EIPS"

# Load Balancers (ALB/NLB)
ELBS=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[*].LoadBalancerArn' --output text | awk -F/ '{print $NF}')
if [ -z "$ELBS" ]; then ELB_COUNT=0; else ELB_COUNT=$(echo "$ELBS" | wc -w); fi
check_status "Load Balancers (ALB/NLB)" "$ELB_COUNT" "$ELBS"

# ---------------------------------------------------
# 4. ALMACENAMIENTO (EBS Huérfanos)
# ---------------------------------------------------
echo -e "\n🔍 Verificando Almacenamiento..."

# Volúmenes EBS (Todos cobran, verificamos especialmente los 'available' que son huérfanos)
VOLUMES=$(aws ec2 describe-volumes --region $REGION --query 'Volumes[*].VolumeId' --output text)
if [ -z "$VOLUMES" ]; then VOL_COUNT=0; else VOL_COUNT=$(echo "$VOLUMES" | wc -w); fi
check_status "EBS Volumes (Total)" "$VOL_COUNT" "$VOLUMES"

# ---------------------------------------------------
# 5. RESTOS DE INFRAESTRUCTURA (VPCs & SGs)
# ---------------------------------------------------
echo -e "\n🔍 Verificando Estructura Base..."

# VPCs (No cobran por existir, pero indican si Terraform borró todo)
VPCS=$(aws ec2 describe-vpcs --region $REGION --query 'Vpcs[*].VpcId' --output text)
if [ -z "$VPCS" ]; then VPC_COUNT=0; else VPC_COUNT=$(echo "$VPCS" | wc -w); fi
check_status "VPCs (Incluye Default)" "$VPC_COUNT" "$VPCS"

# Security Groups
SGS=$(aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[*].GroupId' --output text)
if [ -z "$SGS" ]; then SG_COUNT=0; else SG_COUNT=$(echo "$SGS" | wc -w); fi
check_status "Security Groups" "$SG_COUNT" "$SGS"

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${BLUE}               AUDITORÍA FINALIZADA                  ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "Nota: Si ves recursos en ROJO, verifica si son del proyecto o recursos por defecto de la cuenta."
