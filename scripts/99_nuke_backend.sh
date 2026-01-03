#!/bin/bash
set -e

# ==============================================================================
# ☢️ SCRIPT: 99_nuke_backend.sh
# DESCRIPCIÓN: Elimina el Backend S3 para dejar costo $0.
# PRECAUCIÓN:  ESTO ES IRREVERSIBLE.
# ==============================================================================

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT_NAME="eks-enterprise-ingress"
BUCKET_NAME="${PROJECT_NAME}-state-${ACCOUNT_ID}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}☢️  INICIANDO DESTRUCCIÓN DEL BACKEND: $BUCKET_NAME ☢️${NC}"
read -p "¿Estás SEGURO? (escribe 'si' para continuar): " confirm
if [ "$confirm" != "si" ]; then exit 1; fi

if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ El bucket no existe. Nada que borrar."
    exit 0
fi

echo -e "${YELLOW}⏳ Vaciando versiones y marcadores de borrado...${NC}"

# Borrar versiones de objetos
aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json --query 'Versions[].{Key:Key,VersionId:VersionId}' | \
jq -r '.[] | select(.Key != null) | [.Key, .VersionId] | @tsv' | \
while IFS=$'\t' read -r key versionId; do
    echo "Borrando versión: $key"
    aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$versionId"
done

# Borrar marcadores de eliminación
aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' | \
jq -r '.[] | select(.Key != null) | [.Key, .VersionId] | @tsv' | \
while IFS=$'\t' read -r key versionId; do
    echo "Borrando marcador: $key"
    aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$versionId"
done

echo -e "${YELLOW}🗑️  Eliminando el bucket...${NC}"
aws s3 rb "s3://${BUCKET_NAME}" --force

echo -e "${RED}✅ BACKEND ELIMINADO CORRECTAMENTE.${NC}"# ------------------------------------------------------------------------------
# NUCLEAR: Elimina Bucket S3 y DynamoDB (Solo ejecutar al final)
# ------------------------------------------------------------------------------

