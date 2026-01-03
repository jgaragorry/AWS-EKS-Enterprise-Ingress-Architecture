#!/bin/bash

# ==============================================================================
# 🏗️ SCRIPT: make_enterprise_structure.sh
# ------------------------------------------------------------------------------
# AUTOR: Jorge Garagorry
# DESCRIPCIÓN: Genera la estructura de directorios para el Workshop Enterprise EKS.
#              Incluye placeholders para Terragrunt, Scripts de FinOps y Backend.
# ESTRATEGIA:  Arquitectura modular (live/modules) compatible con Terragrunt DRY.
# IDEMPOTENCIA: Verifica si los directorios existen antes de crearlos.
# ==============================================================================

PROJECT_ROOT="aws-eks-ingress-architecture"
echo "🚀 Iniciando creación de estructura Enterprise para: $PROJECT_ROOT"

# Función para crear directorios de forma segura
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "✅ Creado directorio: $1"
    else
        echo "⚠️  Directorio ya existe (Omitido): $1"
    fi
}

# Función para crear archivos vacíos con comentarios de cabecera
create_file() {
    local filepath="$1"
    local description="$2"
    
    if [ ! -f "$filepath" ]; then
        touch "$filepath"
        echo "# ------------------------------------------------------------------------------" > "$filepath"
        echo "# $description" >> "$filepath"
        echo "# ------------------------------------------------------------------------------" >> "$filepath"
        echo "" >> "$filepath"
        echo "✅ Creado archivo: $filepath"
    fi
}

# 1. Crear Raíz del Proyecto
create_dir "$PROJECT_ROOT"
cd "$PROJECT_ROOT" || exit

# 2. Crear Estructura de Módulos (Lógica Terraform)
#    Separamos Network (VPC) de Compute (EKS) para mejor control
create_dir "modules/vpc-network"
create_dir "modules/eks-cluster"
create_dir "modules/k8s-addons" # Para Ingress Controller y CertManager

# Crear archivos base de Terraform en los módulos
for module in vpc-network eks-cluster k8s-addons; do
    create_file "modules/$module/main.tf" "Lógica principal del recurso para $module"
    create_file "modules/$module/variables.tf" "Definición de variables de entrada para $module"
    create_file "modules/$module/outputs.tf" "Outputs para consumir en otros módulos"
    create_file "modules/$module/versions.tf" "Restricciones de versiones de proveedores"
done

# 3. Crear Estructura Live (Implementación Terragrunt)
#    Solo haremos 'prod' para este lab para enfocar recursos, pero dejamos estructura lista
create_dir "live/prod/vpc"
create_dir "live/prod/eks"
create_dir "live/prod/addons"

# Crear archivos terragrunt.hcl hijos
create_file "live/prod/vpc/terragrunt.hcl" "Instanciación del módulo VPC para PROD"
create_file "live/prod/eks/terragrunt.hcl" "Instanciación del módulo EKS para PROD (Depende de VPC)"
create_file "live/prod/addons/terragrunt.hcl" "Instanciación de Addons (Depende de EKS)"

# Crear terragrunt.hcl padre (DRY Backend)
create_file "live/terragrunt.hcl" "Configuración RAÍZ: Backend S3 Dinámico y Provider AWS Global"

# 4. Crear Scripts de Automatización y FinOps (El corazón operativo)
create_dir "scripts"

# Script: Init Backend
create_file "scripts/00_init_backend.sh" "Script Idempotente: Crea Bucket S3 + DynamoDB Lock con Cifrado"
chmod +x scripts/00_init_backend.sh

# Script: Monitor Backend
create_file "scripts/01_check_backend.sh" "Script de Verificación: Valida acceso y existencia del Backend"
chmod +x scripts/01_check_backend.sh

# Script: FinOps Audit (El más importante)
create_file "scripts/audit_resources.sh" "AUDITORIA EXHAUSTIVA: Busca EKS, ELB, ENI, EBS, NAT GWs huérfanos"
chmod +x scripts/audit_resources.sh

# Script: Destroy (Wrapper)
create_file "scripts/destroy_all.sh" "Script de Destrucción Controlada (Orden inverso: Addons -> EKS -> VPC)"
chmod +x scripts/destroy_all.sh

# Script: Nuke Backend
create_file "scripts/99_nuke_backend.sh" "NUCLEAR: Elimina Bucket S3 y DynamoDB (Solo ejecutar al final)"
chmod +x scripts/99_nuke_backend.sh

# 5. Documentación
create_file "README.md" "Documentación General del Proyecto"
create_file "ARCHITECTURE.md" "Diagramas y Decisiones de Arquitectura"
create_file ".gitignore" "Ignorar .terraform, .terragrunt-cache, tfstate local"

# Poblar .gitignore básico
cat <<EOF > .gitignore
.terraform/
.terragrunt-cache/
*.tfstate
*.tfstate.backup
.DS_Store
*.log
EOF

echo "----------------------------------------------------------------"
echo "🎉 Estructura Enterprise creada exitosamente en: $PROJECT_ROOT"
echo "📂 Revisa la carpeta 'scripts' para comenzar con la configuración."
echo "----------------------------------------------------------------"
