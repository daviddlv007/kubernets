# 🚀 Setup Completo con GHCR + ArgoCD

## ✅ Configuración completada para usuario: daviddlv007

---

## 📦 Paso 1: Construir y subir imágenes (5 min)

```bash
# Construir y subir a GHCR
./scripts/build-and-push.sh
```

Este script:
1. ✅ Login en GHCR con tu token
2. ✅ Construye Service A y Service B
3. ✅ Sube las imágenes a ghcr.io/daviddlv007/

---

## 🌐 Paso 2: Hacer imágenes públicas (2 min)

**Importante:** Por defecto las imágenes en GHCR son privadas.

1. Ve a: https://github.com/daviddlv007?tab=packages
2. Verás 2 paquetes: `service-a` y `service-b`
3. Click en cada paquete → **Package settings**
4. Scroll abajo → **Change visibility** → **Public**
5. Confirma escribiendo el nombre del paquete

---

## 🎯 Paso 3: Subir proyecto a GitHub (3 min)

```bash
cd /home/ubuntu/proyectos/kubernets

# Inicializar git
git init

# Agregar archivos
git add .

# Commit inicial
git commit -m "Initial commit: Multi-cloud K8s with ArgoCD + GHCR"

# Crear repo en GitHub:
# 1. Ve a https://github.com/new
# 2. Nombre: kubernets
# 3. Visibilidad: Public
# 4. NO marques "Initialize with README"
# 5. Click "Create repository"

# Conectar y push
git remote add origin https://github.com/daviddlv007/kubernets.git
git branch -M main
git push -u origin main
```

---

## 🚀 Paso 4: Instalar ArgoCD (10 min)

```bash
# Cambiar a cluster1
kubectl config use-context k3d-cluster1

# Instalar ArgoCD
./argocd/install.sh

# Guardar el password que aparece
```

---

## 📊 Paso 5: Acceder al dashboard (2 min)

```bash
# En una terminal nueva
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Abrir en navegador:
# https://localhost:8080

# Credenciales:
# Usuario: admin
# Password: (el que te dio el script)
```

**⚠️ Acepta el certificado autofirmado del navegador**

---

## 🎯 Paso 6: Desplegar applications (2 min)

```bash
# Aplicar configuraciones de ArgoCD
kubectl apply -f argocd/applications/service-a.yaml
kubectl apply -f argocd/applications/service-b.yaml

# Ver en dashboard
# https://localhost:8080
```

Deberías ver:
```
┌─────────────┬──────────┬──────────┬─────────┐
│ Name        │ Status   │ Health   │ Sync    │
├─────────────┼──────────┼──────────┼─────────┤
│ service-a   │ Synced   │ Healthy  │ Auto    │
│ service-b   │ Synced   │ Healthy  │ Auto    │
└─────────────┴──────────┴──────────┴─────────┘
```

---

## 🎉 Workflow desde ahora:

```bash
# 1. Editar código
vim services/service-a/app.py

# 2. Reconstruir y subir
./scripts/build-and-push.sh

# 3. (Opcional) Actualizar tag en deployment.yaml si cambiaste versión

# 4. Commit y push
git add .
git commit -m "Updated service A"
git push

# 5. ArgoCD despliega automáticamente en 1-3 minutos
# Ver en: https://localhost:8080
```

---

## 🔍 Verificar despliegue

```bash
# Ver pods
kubectl get pods

# Ver logs
kubectl logs -l app=service-a
kubectl logs -l app=service-b

# Ver estado de ArgoCD apps
kubectl get applications -n argocd
```

---

## 🌐 Para despliegue multi-cloud (VMs):

Una vez que funcione localmente:

```bash
# En cada VM ejecutar:
ssh user@vm1

# Instalar K3s
curl -sfL https://get.k3s.io | sh -

# Instalar ArgoCD
./argocd/install.sh

# Aplicar applications
kubectl apply -f argocd/applications/
```

**Ventaja:** Todas las VMs sincronizarán automáticamente desde el mismo repo de GitHub.

---

## 🛠️ Troubleshooting

### Error: "unauthorized: unauthenticated"
```bash
# Re-login en GHCR
./scripts/ghcr-login.sh
```

### ArgoCD no puede pull imágenes
```bash
# Verificar que las imágenes son públicas
# https://github.com/daviddlv007?tab=packages
```

### Application en estado "Unknown"
```bash
# Verificar que el repo de GitHub existe y es público
# https://github.com/daviddlv007/kubernets
```

---

## ✅ Checklist

- [ ] Ejecutar `./scripts/build-and-push.sh`
- [ ] Hacer imágenes públicas en GitHub
- [ ] Crear repo `kubernets` en GitHub
- [ ] Push del proyecto a GitHub
- [ ] Instalar ArgoCD: `./argocd/install.sh`
- [ ] Port-forward y acceder al dashboard
- [ ] Aplicar applications
- [ ] Verificar que todo está "Synced" y "Healthy"

---

## 📋 Resumen de archivos configurados:

✅ `scripts/ghcr-login.sh` - Login automático en GHCR
✅ `scripts/build-and-push.sh` - Build y push de imágenes
✅ `services/*/k8s/deployment.yaml` - Actualizados con imágenes de GHCR
✅ `argocd/applications/*.yaml` - Configurados con tu repo de GitHub
✅ `.gitignore` - Token protegido (no se subirá a GitHub)

---

**🎯 Siguiente paso:** Ejecuta `./scripts/build-and-push.sh`
