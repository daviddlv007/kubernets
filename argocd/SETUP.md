# 🚀 Setup ArgoCD - Guía Rápida (30 minutos)

## 📋 Prerrequisitos

- ✅ Clusters k3d corriendo: `make status`
- ✅ Cuenta de GitHub
- ✅ Git instalado

---

## 🎯 Pasos para Setup Completo

### **PASO 1: Subir proyecto a GitHub (5 min)**

```bash
cd /home/ubuntu/proyectos/kubernets

# Inicializar Git si no lo has hecho
git init

# Agregar archivos
git add .
git commit -m "Initial commit: Multi-cloud Kubernetes project"

# Crear repo en GitHub:
# 1. Ve a https://github.com/new
# 2. Nombre: kubernets (o el que prefieras)
# 3. Visibilidad: Public (ArgoCD necesita acceso)
# 4. NO marques "Initialize with README"
# 5. Click "Create repository"

# Conectar con GitHub
git remote add origin https://github.com/TU_USUARIO/kubernets.git
git branch -M main
git push -u origin main
```

---

### **PASO 2: Actualizar imágenes para usar Docker Hub (5 min)**

ArgoCD necesita que las imágenes estén en un registry público:

```bash
# Login a Docker Hub
docker login

# Construir y subir Service A
docker build -t TU_DOCKERHUB_USER/service-a:latest services/service-a/
docker push TU_DOCKERHUB_USER/service-a:latest

# Construir y subir Service B
docker build -t TU_DOCKERHUB_USER/service-b:latest services/service-b/
docker push TU_DOCKERHUB_USER/service-b:latest
```

Actualizar manifiestos:

**`services/service-a/k8s/deployment.yaml`:**
```yaml
# Cambiar:
image: service-a:latest
imagePullPolicy: Never

# Por:
image: TU_DOCKERHUB_USER/service-a:latest
imagePullPolicy: Always
```

**`services/service-b/k8s/deployment.yaml`:**
```yaml
# Cambiar:
image: service-b:latest
imagePullPolicy: Never

# Por:
image: TU_DOCKERHUB_USER/service-b:latest
imagePullPolicy: Always
```

Commitear cambios:
```bash
git add services/*/k8s/deployment.yaml
git commit -m "Update images to use Docker Hub"
git push
```

---

### **PASO 3: Instalar ArgoCD (10 min)**

```bash
# Cambiar contexto a cluster1
kubectl config use-context k3d-cluster1

# Instalar ArgoCD
./argocd/install.sh

# Guardar el password que aparece
```

---

### **PASO 4: Acceder al Dashboard (2 min)**

```bash
# En una terminal nueva, ejecutar:
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Abrir navegador en:
# https://localhost:8080

# Credenciales:
# Usuario: admin
# Password: (el que te dio el script anterior)

# ⚠️ IMPORTANTE: Acepta el certificado autofirmado del navegador
```

---

### **PASO 5: Configurar Applications (5 min)**

**Editar archivos de aplicación:**

`argocd/applications/service-a.yaml`:
```yaml
source:
  repoURL: https://github.com/TU_USUARIO/kubernets.git  # ⬅️ CAMBIA ESTO
```

`argocd/applications/service-b.yaml`:
```yaml
source:
  repoURL: https://github.com/TU_USUARIO/kubernets.git  # ⬅️ CAMBIA ESTO
```

**Aplicar configuraciones:**

```bash
# Aplicar applications
kubectl apply -f argocd/applications/service-a.yaml
kubectl apply -f argocd/applications/service-b.yaml

# Ver en el dashboard
# https://localhost:8080
```

---

### **PASO 6: Verificar en Dashboard (3 min)**

En el dashboard de ArgoCD deberías ver:

```
┌─────────────────────────────────────────────┐
│  Applications                                │
├─────────────┬──────────┬──────────┬─────────┤
│ Name        │ Status   │ Health   │ Sync    │
├─────────────┼──────────┼──────────┼─────────┤
│ service-a   │ Synced   │ Healthy  │ Auto    │
│ service-b   │ Synced   │ Healthy  │ Auto    │
└─────────────┴──────────┴──────────┴─────────┘
```

---

## 🎉 ¡Listo! Ahora el workflow es:

```bash
# 1. Editar código
vim services/service-a/app.py

# 2. Reconstruir y subir imagen
docker build -t TU_DOCKERHUB_USER/service-a:v2 services/service-a/
docker push TU_DOCKERHUB_USER/service-a:v2

# 3. Actualizar manifest
vim services/service-a/k8s/deployment.yaml
# Cambiar image: service-a:v2

# 4. Commit y push
git add .
git commit -m "Updated service A"
git push

# 5. ArgoCD despliega automáticamente en 1-3 minutos
# Ver en dashboard: https://localhost:8080
```

---

## 🌐 Para Despliegue Multi-Cloud (VMs reales)

Una vez que funcione localmente:

### **Opción A: ArgoCD en VM Central**
```bash
# Instalar ArgoCD en VM1
ssh user@vm1
./argocd/install.sh

# Registrar otros clusters (VM2, VM3, VM4)
argocd cluster add vm2-context
argocd cluster add vm3-context
argocd cluster add vm4-context

# Crear Applications apuntando a diferentes clusters
```

### **Opción B: ArgoCD en cada VM** (Más simple)
```bash
# En cada VM:
ssh user@vm1 './argocd/install.sh'
ssh user@vm2 './argocd/install.sh'
ssh user@vm3 './argocd/install.sh'
ssh user@vm4 './argocd/install.sh'

# Cada VM sincroniza desde el mismo repo de GitHub
```

---

## 🔧 Comandos Útiles

```bash
# Ver estado de aplicaciones
kubectl get applications -n argocd

# Forzar sincronización manual
kubectl patch application service-a -n argocd \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'

# Ver logs de ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50

# Reiniciar sincronización
kubectl delete application service-a -n argocd
kubectl apply -f argocd/applications/service-a.yaml

# Desinstalar ArgoCD
kubectl delete namespace argocd
```

---

## ⚡ Ventajas de Esta Configuración

✅ **Un solo `git push` despliega todo**
✅ **Dashboard visual del estado**
✅ **Rollback con un click**
✅ **Auditoría completa de cambios**
✅ **Funciona igual localmente y en VMs**
✅ **GitOps real (industry standard)**

---

## 📊 Timeline

```
Minuto 0-5:   GitHub setup + push inicial
Minuto 5-10:  Construir y subir imágenes a Docker Hub
Minuto 10-20: Instalar ArgoCD
Minuto 20-25: Configurar Applications
Minuto 25-30: Verificar dashboard y primer despliegue

TOTAL: 30 minutos
```

---

## 🆘 Troubleshooting

### ArgoCD no sincroniza
```bash
# Ver detalles del Application
kubectl describe application service-a -n argocd

# Ver eventos
kubectl get events -n argocd --sort-by='.lastTimestamp'
```

### No puedo acceder al dashboard
```bash
# Verificar que port-forward esté corriendo
ps aux | grep port-forward

# Reiniciar port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Application en estado "Unknown"
```bash
# Significa que ArgoCD no puede acceder al repo de GitHub
# Verificar que el repo sea público
# O configurar SSH keys en ArgoCD
```

---

¿Listo para empezar? Ejecuta:
```bash
./argocd/install.sh
```
