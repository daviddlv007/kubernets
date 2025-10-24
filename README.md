# 🚀 Multi-Cloud Kubernetes + GitOps Automático

> Despliegue multi-cloud con K3s + GitOps | Local → Nube con CI/CD automático

## 📋 ¿Qué es este proyecto?

Sistema de microservicios multi-cloud con **despliegue automático desde GitHub**.

- **2+ microservicios** en **múltiples clusters** (local o VMs reales)
- **GitOps automático** - Un `git push` despliega en todas las VMs
- **CI/CD minimalista** - 100 líneas de bash, cero configuración compleja
- **GHCR** para imágenes públicas

```
┌─────────────────┐         ┌─────────────────┐
│   Cluster 1     │         │   Cluster 2     │
│   (K3s)         │         │   (K3s)         │
│                 │         │                 │
│  ┌───────────┐  │  HTTP   │  ┌───────────┐  │
│  │Service A  │──┼────────>│  │Service B  │  │
│  │(Python)   │  │         │  │(Node.js)  │  │
│  │Port: 8080 │  │         │  │Port: 8080 │  │
│  └───────────┘  │         │  └───────────┘  │
└─────────────────┘         └─────────────────┘
        │                           │
        └───────────┬───────────────┘
                    ↓
            ┌──────────────┐
            │   ArgoCD     │
            │  (GitOps)    │
            └──────────────┘
```

---

## ⚡ Quick Start Local (5 minutos)

```bash
# 1. Prerequisitos
make check-deps

# 2. Crear clusters locales
make create-clusters

# 3. Setup GitOps automático
./scripts/setup-gitops.sh

# 4. ¡Listo! Ahora cada git push despliega automáticamente

# Ver logs del GitOps
sudo journalctl -u gitops -f
```

## 🌐 Despliegue en VMs (Multi-Cloud Real)

```bash
# En cada VM (AWS, GCP, Azure, DigitalOcean, etc.)
ssh user@vm-ip

# 1. Instalar K3s
curl -sfL https://get.k3s.io | sh -

# 2. Clonar repo
git clone https://github.com/daviddlv007/kubernets.git
cd kubernets

# 3. Setup GitOps (especificar VM: vm1, vm2, vm3, vm4)
./scripts/setup-vm-gitops.sh vm1

# ¡Listo! Ahora cada git push despliega en todas las VMs automáticamente

# Ver documentación completa
cat docs/VM_DEPLOYMENT.md
```

---

## 🛠️ Prerequisitos

**Local:**
- Docker (para k3d)
- kubectl
- k3d

**VMs en la nube:**
- Ubuntu/Debian
- 2GB RAM mínimo
- Puertos 6443, 80, 443 abiertos

**Instalación automática local:**
```bash
./scripts/install-tools.sh
```

---

## 📦 Componentes

### Service A (Python/Flask)
- **Endpoint**: `GET /call` 
- **Función**: Llama a Service B y retorna la respuesta
- **Puerto**: 8080
- **Imagen**: `ghcr.io/daviddlv007/service-a:latest`

### Service B (Node.js/Express)
- **Endpoint**: `GET /hello`
- **Función**: Responde con mensaje
- **Puerto**: 8080
- **Imagen**: `ghcr.io/daviddlv007/service-b:latest`

### GitOps Automático
- **Sincronización**: Cada 30 segundos desde GitHub
- **Logs**: `sudo journalctl -u gitops -f`
- **Función**: Despliegue automático multi-cluster/multi-cloud

---

## 🎯 Comandos Útiles

```bash
# Gestión Local
make create-clusters       # Crear clusters k3d
./scripts/setup-gitops.sh  # Configurar GitOps automático
sudo journalctl -u gitops -f  # Ver logs de despliegues

# Desarrollo
./scripts/build-and-push.sh   # Build y push a GHCR
git add . && git commit -m "Update" && git push  # Desplegar automáticamente

# VMs
./scripts/setup-vm-gitops.sh vm1  # Setup en VM específica
ssh user@vm1 "sudo journalctl -u gitops -f"  # Ver logs remotos
make argocd-ui             # Abrir dashboard
make argocd-password       # Ver password admin

# Servicios
make deploy-services       # Desplegar ambos servicios
make test                  # Probar comunicación
make logs-service-a        # Ver logs Service A
make logs-service-b        # Ver logs Service B

# Desarrollo
make build-images          # Construir imágenes Docker
make push-images           # Subir a registry (opcional)

# Utilidades
make status               # Ver estado general
make clean                # Limpiar todo
```

---

## 🌐 Migración a Cloud

### Para AWS + GCP (ejemplo)

```bash
# 1. Crear VMs en cada cloud
# AWS: EC2 t2.micro
# GCP: e2-micro

# 2. Ejecutar en cada VM
curl -sfL https://get.k3s.io | sh -

# 3. Obtener kubeconfigs
scp user@aws-vm:/etc/rancher/k3s/k3s.yaml ~/.kube/aws-cluster
scp user@gcp-vm:/etc/rancher/k3s/k3s.yaml ~/.kube/gcp-cluster

# 4. Usar MISMOS manifiestos
kubectl --context=aws-cluster apply -f services/service-a/k8s/
kubectl --context=gcp-cluster apply -f services/service-b/k8s/

# 5. O mejor: conectar clusters a ArgoCD
argocd cluster add aws-cluster
argocd cluster add gcp-cluster
```

**El código NO cambia**, solo los contextos de kubectl.

---

## 📚 Arquitectura Detallada

### Local (Desarrollo)
- **Cluster 1**: k3d en puerto 6550 (simula AWS)
- **Cluster 2**: k3d en puerto 6551 (simula GCP)
- **ArgoCD**: Instalado en cluster1, gestiona ambos
- **Networking**: Traefik LoadBalancer (incluido en K3s)

### Cloud (Producción)
- **Cluster 1**: K3s en VM AWS EC2
- **Cluster 2**: K3s en VM GCP Compute Engine
- **ArgoCD**: Mismo, gestiona ambos clusters
- **Networking**: IPs públicas + DNS

---

## 🔍 Troubleshooting

```bash
# Ver estado de clusters
kubectl config get-contexts

# Ver pods en cluster1
kubectl --context=k3d-cluster1 get pods -A

# Ver pods en cluster2
kubectl --context=k3d-cluster2 get pods -A

# Logs de ArgoCD
kubectl --context=k3d-cluster1 logs -n argocd -l app.kubernetes.io/name=argocd-server

# Reiniciar todo
make clean && make create-clusters && make install-argocd && make deploy-services
```

---

## 📖 Flujo GitOps

```
┌──────────────┐
│   Git Push   │
└──────┬───────┘
       │
       ↓
┌──────────────┐
│   ArgoCD     │ ← Detecta cambios
│  (Polling)   │
└──────┬───────┘
       │
       ├─────────────┐
       ↓             ↓
┌────────────┐  ┌────────────┐
│ Cluster 1  │  │ Cluster 2  │
│  Sync      │  │  Sync      │
└────────────┘  └────────────┘
```

1. Modificas código o manifiestos
2. `git commit && git push`
3. ArgoCD detecta cambios (cada 3min)
4. ArgoCD despliega automáticamente a los clusters correspondientes
5. Verificas en dashboard

---

## 🎓 Conceptos Aprendidos

- ✅ Kubernetes multi-cluster
- ✅ GitOps con ArgoCD
- ✅ Microservicios containerizados
- ✅ Service discovery entre clusters
- ✅ Infraestructura como código
- ✅ K3s (Kubernetes ligero)
- ✅ Comunicación inter-cluster

---

## 📝 Notas

- **K3d vs K3s**: K3d corre K3s en Docker (desarrollo local). K3s se instala directo en VMs (producción).
- **Persistencia**: Los clusters k3d NO persisten al reiniciar Docker por defecto.
- **Recursos**: Cada cluster usa ~512MB RAM.
- **Networking**: Service B debe ser accesible públicamente (LoadBalancer o NodePort).

---

## 🤝 Contribuir

Este es un proyecto académico minimalista. Mejoras bienvenidas:
- Agregar más servicios
- Implementar service mesh (Cilium/Istio)
- Agregar monitoring (Prometheus/Grafana)
- CI/CD con GitHub Actions

---

## 📄 Licencia

MIT - Proyecto Académico
