#!/bin/bash
set -e

# ==============================================================================
# 🛡️ SCRIPT: 00_init_backend.sh (Versión TF 1.10+ Native Locking)
# DESCRIPCIÓN: Bootstrapping del Backend S3.
# CAMBIOS:     Eliminada creación de DynamoDB. Se usará S3 Native Locking.
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🏗️  Iniciando Setup del Backend S3 (Native Locking)...${NC}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
PROJECT_NAME="eks-enterprise-ingress"
BUCKET_NAME="${PROJECT_NAME}-state-${ACCOUNT_ID}"

echo "🪣 Bucket Objetivo: $BUCKET_NAME"

# Crear Bucket S3
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  El bucket ya existe.${NC}"
else
    echo -e "${BLUE}🚀 Creando bucket...${NC}"
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    
    # Bloquear acceso público
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

    # Activar Versionado (Obligatorio para recuperación)
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    # Activar Cifrado AES256
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
    
    echo -e "${GREEN}✅ Bucket S3 creado y asegurado.${NC}"
fi

echo "------------------------------------------------"
echo -e "${YELLOW}👉 COPIA ESTO para tu live/root.hcl:${NC}"
echo -e "${BLUE}bucket = \"$BUCKET_NAME\"${NC}"
echo -e "${BLUE}use_lockfile = true${NC}"
