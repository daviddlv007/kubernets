# 🌐 Guía de Despliegue a 4 VMs Reales

## 📋 Contexto

Tienes 4 VMs en diferentes clouds y quieres desplegar servicios en cada una.

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   VM1       │   │   VM2       │   │   VM3       │   │   VM4       │
│  (AWS/DO)   │   │  (GCP/DO)   │   │ (Azure/DO)  │   │  (otro)     │
│             │   │             │   │             │   │             │
│  K3s        │   │  K3s        │   │  K3s        │   │  K3s        │
│  Service A  │   │  Service B  │   │  Service C  │   │  Service D  │
└─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
```

---

## 🎯 Dos Estrategias de Despliegue

### **Estrategia 1: Manual con kubectl** (Sin ArgoCD)

**Cuándo usar:**
- ✅ Proyecto académico/personal
- ✅ Despliegues poco frecuentes
- ✅ Control total del proceso
- ✅ No requiere GitHub

**Flujo:**
```bash
1. Cambias código localmente
2. Construyes imágenes
3. Subes a Docker Hub
4. Ejecutas kubectl apply en cada VM
```

---

### **Estrategia 2: GitOps con ArgoCD** (Recomendada para 4+ VMs)

**Cuándo usar:**
- ✅ Múltiples VMs/Clusters
- ✅ Despliegues frecuentes
- ✅ Trabajo en equipo
- ✅ Necesitas auditoría

**Flujo:**
```bash
1. Cambias código localmente
2. git commit + git push
3. ArgoCD despliega automáticamente a TODAS las VMs
```

---

## 🚀 Implementación Paso a Paso

### **PASO 1: Preparar VMs (Todas las VMs)**

```bash
# Conectarse a cada VM
ssh user@vm1-ip
ssh user@vm2-ip
ssh user@vm3-ip
ssh user@vm4-ip

# En cada VM ejecutar:
# 1. Instalar K3s
curl -sfL https://get.k3s.io | sh -

# 2. Verificar instalación
sudo k3s kubectl get nodes

# 3. Configurar firewall (si es necesario)
sudo ufw allow 6443/tcp  # API Kubernetes
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
```

---

### **PASO 2A: Despliegue Manual (Sin ArgoCD)**

#### **2.1. Configurar kubectl local**

```bash
# En tu laptop/PC

# Obtener kubeconfig de cada VM
scp user@vm1-ip:/etc/rancher/k3s/k3s.yaml ~/.kube/vm1-config
scp user@vm2-ip:/etc/rancher/k3s/k3s.yaml ~/.kube/vm2-config
scp user@vm3-ip:/etc/rancher/k3s/k3s.yaml ~/.kube/vm3-config
scp user@vm4-ip:/etc/rancher/k3s/k3s.yaml ~/.kube/vm4-config

# Editar cada config (reemplazar 127.0.0.1 con IP pública)
sed -i 's/127.0.0.1/VM1_PUBLIC_IP/g' ~/.kube/vm1-config
sed -i 's/127.0.0.1/VM2_PUBLIC_IP/g' ~/.kube/vm2-config
sed -i 's/127.0.0.1/VM3_PUBLIC_IP/g' ~/.kube/vm3-config
sed -i 's/127.0.0.1/VM4_PUBLIC_IP/g' ~/.kube/vm4-config

# Renombrar contextos para que sean únicos
sed -i 's/name: default/name: vm1-cluster/g' ~/.kube/vm1-config
sed -i 's/name: default/name: vm2-cluster/g' ~/.kube/vm2-config
sed -i 's/name: default/name: vm3-cluster/g' ~/.kube/vm3-config
sed -i 's/name: default/name: vm4-cluster/g' ~/.kube/vm4-config

# Merge todos los configs
export KUBECONFIG=~/.kube/config:~/.kube/vm1-config:~/.kube/vm2-config:~/.kube/vm3-config:~/.kube/vm4-config
kubectl config view --flatten > ~/.kube/config-all
mv ~/.kube/config-all ~/.kube/config

# Verificar contextos
kubectl config get-contexts
```

#### **2.2. Construir y subir imágenes**

```bash
# Construir imágenes localmente
docker build -t YOUR_DOCKERHUB_USER/service-a:latest services/service-a/
docker build -t YOUR_DOCKERHUB_USER/service-b:latest services/service-b/

# Login a Docker Hub
docker login

# Subir imágenes
docker push YOUR_DOCKERHUB_USER/service-a:latest
docker push YOUR_DOCKERHUB_USER/service-b:latest
```

#### **2.3. Actualizar manifiestos**

Editar `services/service-a/k8s/deployment.yaml`:
```yaml
# Cambiar:
image: service-a:latest
imagePullPolicy: Never

# Por:
image: YOUR_DOCKERHUB_USER/service-a:latest
imagePullPolicy: Always
```

#### **2.4. Desplegar a cada VM**

```bash
# Desplegar Service A en VM1
kubectl --context=vm1-cluster apply -f services/service-a/k8s/

# Desplegar Service B en VM2
kubectl --context=vm2-cluster apply -f services/service-b/k8s/

# Desplegar Service C en VM3
kubectl --context=vm3-cluster apply -f services/service-c/k8s/

# Desplegar Service D en VM4
kubectl --context=vm4-cluster apply -f services/service-d/k8s/
```

#### **2.5. Verificar despliegues**

```bash
# Ver estado en cada cluster
kubectl --context=vm1-cluster get pods,svc
kubectl --context=vm2-cluster get pods,svc
kubectl --context=vm3-cluster get pods,svc
kubectl --context=vm4-cluster get pods,svc
```

---

### **PASO 2B: Despliegue con ArgoCD (Recomendado)**

#### **2.1. Subir proyecto a GitHub**

```bash
cd /home/ubuntu/proyectos/kubernets

# Inicializar Git
git init
git add .
git commit -m "Initial commit: Multi-cloud K8s project"

# Crear repo en GitHub y conectar
git remote add origin https://github.com/YOUR_USER/kubernets.git
git branch -M main
git push -u origin main
```

#### **2.2. Instalar ArgoCD (en VM1 o laptop)**

```bash
# Crear namespace
kubectl --context=vm1-cluster create namespace argocd

# Instalar ArgoCD
kubectl --context=vm1-cluster apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar a que esté listo
kubectl --context=vm1-cluster wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Obtener password inicial
kubectl --context=vm1-cluster -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Exponer ArgoCD
kubectl --context=vm1-cluster port-forward svc/argocd-server -n argocd 8080:443
# Acceder: https://localhost:8080
# User: admin, Password: el obtenido arriba
```

#### **2.3. Instalar ArgoCD CLI**

```bash
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Login
argocd login localhost:8080
```

#### **2.4. Agregar clusters a ArgoCD**

```bash
# Agregar VM2, VM3, VM4 a ArgoCD
argocd cluster add vm2-cluster
argocd cluster add vm3-cluster
argocd cluster add vm4-cluster

# Verificar
argocd cluster list
```

#### **2.5. Crear ArgoCD Applications**

Crear `argocd/applications/service-a.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: service-a
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USER/kubernets.git
    targetRevision: main
    path: services/service-a/k8s
  destination:
    server: https://VM1_IP:6443  # VM1
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Crear similar para service-b, service-c, service-d apuntando a VM2, VM3, VM4.

```bash
# Aplicar Applications
kubectl --context=vm1-cluster apply -f argocd/applications/

# Ver en dashboard
# https://localhost:8080
```

#### **2.6. Workflow desde ahora**

```bash
# 1. Editar código
vim services/service-a/app.py

# 2. Commit y push
git add .
git commit -m "Updated service A"
git push

# 3. ArgoCD despliega automáticamente a VM1
# (en 3 minutos o menos)

# Ver logs en ArgoCD dashboard
```

---

## 📊 Comparación de Métodos

| Aspecto | Manual (kubectl) | ArgoCD |
|---------|------------------|--------|
| **Setup inicial** | 30 min | 60 min |
| **Despliegue** | 5 min por VM | Automático |
| **Actualización** | kubectl apply x4 | git push |
| **Rollback** | Manual | 1 click |
| **Auditoría** | No | Completa |
| **Requiere GitHub** | No | Sí |
| **Complejidad** | Baja | Media |

---

## 🎯 Mi Recomendación

**Para 4 VMs definitivamente usa ArgoCD** porque:

1. Un `git push` despliega a las 4 VMs automáticamente
2. Dashboard visual para ver estado de todo
3. Rollback instantáneo si algo falla
4. Auditoría completa de cambios
5. Es lo que se usa en producción real

---

## 🛠️ Script Automatizado

Usa el script que creé:

```bash
# Para setup inicial
./scripts/deploy-to-vms.sh
# Selecciona opción 1

# Para desplegar servicios
./scripts/deploy-to-vms.sh
# Selecciona opción 2

# Para ver estado
./scripts/deploy-to-vms.sh
# Selecciona opción 4
```

---

## 🆘 Troubleshooting

### Problema: No puedo conectar a VM
```bash
# Verificar SSH
ssh -v user@vm-ip

# Verificar firewall
ssh user@vm-ip "sudo ufw status"
```

### Problema: kubectl no conecta
```bash
# Verificar kubeconfig
kubectl config get-contexts

# Test de conexión
kubectl --context=vm1-cluster get nodes
```

### Problema: ArgoCD no sincroniza
```bash
# Ver logs de ArgoCD
kubectl --context=vm1-cluster logs -n argocd -l app.kubernetes.io/name=argocd-server

# Forzar sync
argocd app sync service-a
```

---

## ✅ Checklist de Despliegue

- [ ] 4 VMs creadas y accesibles por SSH
- [ ] K3s instalado en cada VM
- [ ] Firewalls configurados
- [ ] Kubeconfigs obtenidos y merged
- [ ] Imágenes construidas y en Docker Hub
- [ ] Manifiestos actualizados con imágenes públicas
- [ ] Servicios desplegados en cada VM
- [ ] Comunicación entre servicios verificada
- [ ] (Opcional) ArgoCD configurado
- [ ] (Opcional) GitHub repo creado

---

¿Necesitas ayuda con algún paso específico?
