# ☁️ Guía de Despliegue en Cloud

Esta guía te ayuda a migrar tu setup local a múltiples proveedores cloud.

## 🎯 Estrategias de Despliegue

### Opción 1: VMs con K3s (Recomendado - Barato)
- **Costo**: ~$5-10/mes por VM
- **Control**: Total
- **Complejidad**: Baja
- **Portabilidad**: 100%

### Opción 2: Managed Kubernetes
- **Costo**: $70+/mes (control plane + nodes)
- **Control**: Limitado
- **Complejidad**: Media
- **Conveniencia**: Alta

### Opción 3: Kubernetes Gratuitos
- **Civo** (free trial $250)
- **Linode** (free trial $100)
- **Oracle Cloud** (always free tier con ARM)

---

## 🚀 Opción 1: VMs Multi-Cloud (Paso a Paso)

### Prerequisitos
```bash
# SSH keys
ssh-keygen -t ed25519 -C "multicloud-k8s"

# Terraform (opcional)
brew install terraform  # macOS
sudo apt install terraform  # Linux
```

---

### 📍 Provider 1: DigitalOcean (Más Simple)

#### 1. Crear Droplet
```bash
# Web UI: https://cloud.digitalocean.com/droplets/new
# - Image: Ubuntu 22.04 LTS
# - Plan: Basic ($6/mes, 1GB RAM, 1vCPU)
# - Region: New York
# - Add SSH key

# O con CLI (doctl)
doctl compute droplet create k8s-cluster1 \
  --image ubuntu-22-04-x64 \
  --size s-1vcpu-1gb \
  --region nyc1 \
  --ssh-keys YOUR_SSH_KEY_ID
```

#### 2. Instalar K3s
```bash
# SSH al droplet
ssh root@<droplet-ip>

# Instalar K3s
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Verificar
kubectl get nodes
```

#### 3. Obtener Kubeconfig
```bash
# En tu laptop
scp root@<droplet-ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/do-cluster

# Editar kubeconfig
sed -i 's/127.0.0.1/<droplet-ip>/g' ~/.kube/do-cluster

# Agregar a kubectl
export KUBECONFIG=~/.kube/config:~/.kube/do-cluster
kubectl config view --flatten > ~/.kube/config-merged
mv ~/.kube/config-merged ~/.kube/config

# Probar
kubectl --context=default get nodes
```

---

### 📍 Provider 2: Vultr (Alternativa)

#### 1. Crear Instance
```bash
# Web UI: https://my.vultr.com/deploy/
# - Cloud Compute
# - Location: tu preferencia
# - Image: Ubuntu 22.04
# - Plan: $6/mes (1GB RAM)
```

#### 2. Setup (igual que DO)
```bash
ssh root@<vultr-ip>
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Copiar kubeconfig
# (mismo proceso que DigitalOcean)
```

---

### 📍 Provider 3: Linode (Free $100 credit)

#### 1. Crear Linode
```bash
# Signup: https://login.linode.com/signup
# Create Linode:
# - Distribution: Ubuntu 22.04 LTS
# - Plan: Nanode 1GB ($5/mes)
# - Region: Dallas, TX
```

#### 2. Setup K3s (igual)
```bash
ssh root@<linode-ip>
curl -sfL https://get.k3s.io | sh -
```

---

### 📍 Provider 4: Oracle Cloud (Always Free)

#### 1. Crear Compute Instance
```bash
# https://cloud.oracle.com/compute/instances
# Shape: VM.Standard.E2.1.Micro (Always Free)
# Image: Canonical Ubuntu 22.04
# ⚠️  ARM architecture (funciona igual)
```

#### 2. Configurar Firewall
```bash
# Abrir puertos en Security List
# - 6443 (K8s API)
# - 80, 443 (HTTP/HTTPS)
# - 10250 (Kubelet)
```

#### 3. Instalar K3s
```bash
ssh ubuntu@<oracle-ip>
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

---

## 🐳 Construir y Subir Imágenes

### Opción A: Docker Hub (Gratuito)

```bash
# 1. Login
docker login

# 2. Tag images
docker tag service-a:latest YOUR_USERNAME/service-a:latest
docker tag service-b:latest YOUR_USERNAME/service-b:latest

# 3. Push
docker push YOUR_USERNAME/service-a:latest
docker push YOUR_USERNAME/service-b:latest
```

### Opción B: GitHub Container Registry (Recomendado)

```bash
# 1. Crear Personal Access Token (Settings → Developer → Tokens)
# Scopes: write:packages, read:packages

# 2. Login
echo YOUR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 3. Tag
docker tag service-a:latest ghcr.io/YOUR_USERNAME/service-a:latest
docker tag service-b:latest ghcr.io/YOUR_USERNAME/service-b:latest

# 4. Push
docker push ghcr.io/YOUR_USERNAME/service-a:latest
docker push ghcr.io/YOUR_USERNAME/service-b:latest
```

---

## 📝 Actualizar Manifiestos para Cloud

### services/service-a/k8s/deployment.yaml
```yaml
# Cambiar:
image: service-a:latest
imagePullPolicy: Never

# Por:
image: ghcr.io/YOUR_USERNAME/service-a:latest
imagePullPolicy: Always
```

### services/service-b/k8s/deployment.yaml
```yaml
# Cambiar:
image: service-b:latest
imagePullPolicy: Never

# Por:
image: ghcr.io/YOUR_USERNAME/service-b:latest
imagePullPolicy: Always
```

---

## 🚀 Desplegar en Cloud

```bash
# 1. Verificar contextos
kubectl config get-contexts

# 2. Desplegar Service A en Cluster 1 (ej: DigitalOcean)
kubectl --context=default apply -f services/service-a/k8s/

# 3. Desplegar Service B en Cluster 2 (ej: Vultr)
kubectl --context=vultr-cluster apply -f services/service-b/k8s/

# 4. Esperar a que estén ready
kubectl --context=default get pods -w
kubectl --context=vultr-cluster get pods -w

# 5. Obtener IP pública de Service B
SERVICE_B_IP=$(kubectl --context=vultr-cluster get svc service-b -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $SERVICE_B_IP

# 6. Actualizar Service A con URL de Service B
kubectl --context=default set env deployment/service-a \
  SERVICE_B_URL=http://$SERVICE_B_IP:80

# 7. Verificar
kubectl --context=default get svc service-a
# Obtener IP y probar:
curl http://<service-a-ip>/call
```

---

## 🔐 Configurar Firewall

### DigitalOcean
```bash
# Cloud Firewalls → Create Firewall
# Inbound Rules:
# - SSH (22) - Your IP
# - HTTP (80) - All
# - HTTPS (443) - All
# - K8s API (6443) - Your IP
```

### Vultr
```bash
# Firewall → Add Firewall Group
# Similar a DigitalOcean
```

### Linode
```bash
# Firewalls → Create Firewall
# Rules similares
```

---

## 💰 Estimación de Costos

### Setup Minimalista (2 clusters)

| Provider | Plan | Costo/mes |
|----------|------|-----------|
| DigitalOcean | 1GB Basic | $6 |
| Vultr | 1GB Cloud | $6 |
| **Total** | | **$12** |

### Con Free Tier

| Provider | Plan | Costo |
|----------|------|-------|
| Oracle Cloud | Always Free VM | $0 |
| Linode | Free $100 credit | $0 (3 meses) |
| **Total** | | **$0** |

---

## 🎓 Recomendación para Proyecto Académico

### Setup Ideal:
```
Cluster 1: Oracle Cloud (Free)
Cluster 2: Linode ($5/mes con crédito gratis)
Registry: GitHub Container Registry (Free)

Costo total: $0 por ~3 meses
```

---

## 🔄 Automatización con Terraform

Ver carpeta `cloud/terraform/` para ejemplos de:
- `digitalocean.tf`
- `vultr.tf`
- `linode.tf`

```bash
cd cloud/terraform/digitalocean
terraform init
terraform plan
terraform apply
```

---

## 📊 Monitoreo

### Instalar Prometheus + Grafana

```bash
# En cada cluster
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

# Exponer Grafana
kubectl port-forward svc/prometheus-grafana 3000:80
```

---

## 🆘 Problemas Comunes

### LoadBalancer stuck in Pending
```bash
# K3s no incluye LB externo automáticamente en cloud
# Solución: Cambiar a NodePort

# service.yaml:
type: NodePort
nodePort: 30080  # Service A
nodePort: 30081  # Service B

# Acceder vía: http://<vm-ip>:30080
```

### Cannot pull image
```bash
# Verificar que la imagen es pública o agregar imagePullSecrets
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN

# En deployment.yaml:
spec:
  imagePullSecrets:
  - name: ghcr-secret
```

---

## ✅ Checklist de Migración

- [ ] VMs creadas en 2+ providers
- [ ] K3s instalado en cada VM
- [ ] Kubeconfigs configurados localmente
- [ ] Imágenes subidas a registry público
- [ ] Manifiestos actualizados (image, imagePullPolicy)
- [ ] Firewalls configurados
- [ ] Service A desplegado en Cluster 1
- [ ] Service B desplegado en Cluster 2
- [ ] SERVICE_B_URL actualizada en Service A
- [ ] Comunicación multi-cloud funcionando
- [ ] (Opcional) ArgoCD conectado a ambos clusters

---

## 🎉 Resultado Final

```
☁️  Cluster 1 (DigitalOcean NYC)
    └── Service A (Python)
         └── Llama a →

☁️  Cluster 2 (Vultr Paris)
    └── Service B (Node.js)
         └── Responde ✅

Comunicación: HTTP público entre VMs
Orquestación: ArgoCD desde laptop
Costo: $12/mes (o gratis con free tiers)
```
