# 🚀 Multi-Cloud Kubernetes - Proyecto Minimalista

> Orquestación multi-cluster con K3s + ArgoCD | Local → Cloud sin cambios

## 📋 ¿Qué es este proyecto?

Simulación local de arquitectura multi-cloud con Kubernetes que se replica **idénticamente** en nubes reales.

**2 microservicios** en **2 clusters** diferentes, orquestados con **ArgoCD** (GitOps).

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

## ⚡ Quick Start (5 minutos)

```bash
# 1. Prerequisitos
make check-deps

# 2. Crear clusters locales
make create-clusters

# 3. Instalar ArgoCD
make install-argocd

# 4. Desplegar servicios
make deploy-services

# 5. Probar comunicación
make test

# 6. Ver ArgoCD Dashboard
make argocd-ui
```

---

## 🛠️ Prerequisitos

- **Docker** (para K3d)
- **kubectl** (CLI de Kubernetes)
- **k3d** (K3s in Docker)
- **Git** (para GitOps)

**Instalación automática:**
```bash
make install-tools  # Instala todo lo necesario
```

---

## 📦 Componentes

### Service A (Python/Flask)
- **Endpoint**: `GET /call` 
- **Función**: Llama a Service B y retorna la respuesta
- **Puerto**: 8080

### Service B (Node.js/Express)
- **Endpoint**: `GET /hello`
- **Función**: Responde con mensaje
- **Puerto**: 8080

### ArgoCD
- **Dashboard**: http://localhost:8080 (user: admin)
- **Función**: Orquesta despliegues en ambos clusters desde Git

---

## 🎯 Comandos Útiles

```bash
# Gestión de Clusters
make create-clusters       # Crear ambos clusters
make delete-clusters       # Eliminar todo
make list-clusters         # Ver clusters activos

# ArgoCD
make install-argocd        # Instalar ArgoCD
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
