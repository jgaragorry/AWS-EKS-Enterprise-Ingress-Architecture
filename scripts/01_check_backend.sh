#!/bin/bash
# ==============================================================================
# 🔍 SCRIPT: 01_check_backend.sh
# DESCRIPCIÓN: Monitorea el estado del Backend S3.
# ==============================================================================

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT_NAME="eks-enterprise-ingress"
BUCKET_NAME="${PROJECT_NAME}-state-${ACCOUNT_ID}"

echo "🔍 Inspeccionando Backend: $BUCKET_NAME"
echo "------------------------------------------------"

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ El Bucket existe."
    echo "📂 Archivos de estado (tfstate) encontrados:"
    aws s3 ls "s3://${BUCKET_NAME}" --recursive --human-readable --summarize | grep "tfstate"
else
    echo "❌ El Bucket NO existe o no tienes acceso."
fi# ------------------------------------------------------------------------------
# Script de Verificación: Valida acceso y existencia del Backend
# ------------------------------------------------------------------------------

