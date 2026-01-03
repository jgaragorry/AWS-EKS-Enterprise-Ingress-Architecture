# 🧪 Guía de Entrenamiento: Ciclo de Vida EKS (Paso a Paso)

Este documento es el **Manual de Operaciones**. Su objetivo es guiarte en la ejecución repetitiva del laboratorio para dominar los comandos de Terraform, Terragrunt y Kubernetes.

---

## 🔁 El Ciclo del Éxito (Workflow)

El objetivo es completar este ciclo sin errores:
1.  **Init** (Preparar el terreno)
2.  **Plan & Apply** (Construir Infraestructura)
3.  **Validate** (Probar que funciona)
4.  **Destroy** (Limpiar para evitar costos)

---

## 🏁 Fase 1: Preparación (Solo la primera vez)

Si acabas de clonar el repo o es una cuenta nueva de AWS:

```bash
# 1. Dar permisos de ejecución a los scripts
chmod +x scripts/*.sh

# 2. Inicializar el Backend Remoto (S3 + DynamoDB)
./scripts/00_init_backend.sh
```

---

## 🚀 Fase 2: Despliegue (El Laboratorio)

### Paso 2.1: Capa de Red (VPC)
Siempre desplegamos la red primero. Es la base.

```bash
# Ir al directorio de la VPC
cd live/prod/vpc

# Descargar proveedores y módulos
terragrunt init

# Desplegar (Revisa el plan antes de confirmar o usa auto-approve)
terragrunt apply -auto-approve
```
* **Hito:** Al terminar, tendrás una VPC con NAT Gateway. (A partir de aquí **AWS cobra**).

### Paso 2.2: Capa de Cómputo (EKS Cluster)
Desplegamos el cerebro y los nodos.

```bash
# Ir al directorio del EKS
cd ../eks

# Inicializar
terragrunt init

# Desplegar (Esto tomará ~15-20 minutos)
terragrunt apply -auto-approve
```

---

## 🔧 Fase 3: Resolución de Problemas Comunes

### 🔴 Caso: Timeout del `aws-ebs-csi-driver`
Si ves un error rojo después de 20 minutos que dice `timeout while waiting for state to become 'ACTIVE'`:

1.  **No entres en pánico.** Es una "condición de carrera" normal en laboratorios nuevos.
2.  **Solución Rápida:** Simplemente vuelve a ejecutar el comando:
    ```bash
    terragrunt apply -auto-approve
    ```
    *(La segunda vez funcionará en segundos porque la infraestructura base ya existe).*

### 🔴 Caso: Error de "Lock" (Bloqueo)
Si se corta internet o cancelas el proceso a la mitad, Terraform puede dejar el estado bloqueado en DynamoDB.
* **Solución:** Ve a la consola de AWS -> DynamoDB -> Tablas -> Busca la tabla de "lock" y borra el ítem que contiene el `LockID`.

---

## 🧪 Fase 4: Validación (La Prueba de Fuego)

No confíes en el mensaje verde de Terraform. Verifica que el clúster realmente funcione.

```bash
# 1. Conectar tu terminal local con el clúster de AWS
aws eks update-kubeconfig --region us-east-1 --name eks-enterprise-prod

# 2. Verificar que los nodos están "Ready"
kubectl get nodes

# 3. Lanzar una aplicación de prueba (Nginx)
kubectl run nginx --image=nginx

# 4. Ver en tiempo real cómo nace el pod
kubectl get pods -w
```
* **Éxito:** Cuando veas el estado **`Running`**.
* **Limpieza de prueba:** `kubectl delete pod nginx`

---

## 💣 Fase 5: Destrucción (FinOps - CRÍTICO)

Para asegurar que tu factura sea **$0.00** al terminar la práctica.
**⚠️ ORDEN ESTRICTO:** Primero lo de arriba (Apps/Cluster), luego lo de abajo (Red).

### Paso 5.1: Destruir EKS
```bash
cd ~/AWS-EKS-Enterprise-Ingress-Architecture/live/prod/eks
terragrunt destroy -auto-approve
```
*(Espera a que termine completamente antes de seguir).*

### Paso 5.2: Destruir VPC
```bash
cd ~/AWS-EKS-Enterprise-Ingress-Architecture/live/prod/vpc
terragrunt destroy -auto-approve
```

### Paso 5.3: Auditoría Final (La prueba de la tranquilidad)
Ejecuta este script para dormir tranquilo.

```bash
cd ~/AWS-EKS-Enterprise-Ingress-Architecture
./scripts/audit_resources.sh
```
* **Meta:** Todo debe salir en VERDE `[✔] ... Limpio`.
* **Si sale ROJO:** Entra a la consola de AWS y borra el recurso manualmente.

---

## 🧪 Capítulo Extra: Desplegando el Ambiente DEV (Low-Cost)

Ahora que tienes una arquitectura modular, puedes levantar un entorno de desarrollo paralelo gastando la mitad de dinero.

### 1. Desplegar Red DEV
```bash
cd ~/AWS-EKS-Enterprise-Ingress-Architecture/live/dev/vpc
terragrunt apply -auto-approve
```
*Observa cómo se crea una VPC totalmente nueva llamada `vpc-enterprise-dev`.*

### 2. Desplegar Cluster DEV
```bash
cd ../eks
terragrunt apply -auto-approve
```
*Observa en el output que Terraform creará solo **1 nodo** tipo **t3.small**.*

### 3. Switch de Contexto (Manejo de múltiples clusters)
Para trabajar con DEV sin romper PROD, usa alias en kubectl:

```bash
# Conectar kubectl a DEV
aws eks update-kubeconfig --region us-east-1 --name eks-enterprise-dev --alias dev

# Conectar kubectl a PROD
aws eks update-kubeconfig --region us-east-1 --name eks-enterprise-prod --alias prod

# Cambiar rápido entre ellos
kubectl config use-context dev
kubectl get nodes   # Verás 1 nodo (Dev)

kubectl config use-context prod
kubectl get nodes   # Verás 2 nodos (Prod)
```

---

## 🏆 Retos para dominar el tema

Una vez te sientas cómodo con el ciclo básico, intenta esto en tus próximas repeticiones:

1.  **Cambiar el tipo de instancia:** Ve a `live/prod/eks/terragrunt.hcl` (o el módulo) y cambia `t3.medium` por `t3.large`. Aplica y observa qué pasa.
2.  **Escalar nodos:** Cambia `desired_size = 2` a `3`. Aplica y haz `kubectl get nodes`.
3.  **Romperlo a propósito:** Intenta destruir la VPC sin destruir el EKS. Lee el error que te da AWS (Dependency Violation) para entender cómo se protegen los recursos.

---
_“La repetición es la madre de la retención.”_
