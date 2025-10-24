# 📚 Documentación Técnica

## 🏗️ Arquitectura

### Componentes
```
┌─────────────────────────────────────────────────────────┐
│                    Local Development                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐        ┌──────────────────┐     │
│  │  Cluster 1 (k3d) │        │  Cluster 2 (k3d) │     │
│  │  Port: 6550      │        │  Port: 6551      │     │
│  │                  │        │                  │     │
│  │  ┌────────────┐  │        │  ┌────────────┐  │     │
│  │  │ Service A  │  │ HTTP   │  │ Service B  │  │     │
│  │  │ (Python)   │──┼───────>│  │ (Node.js)  │  │     │
│  │  │ Port: 8080 │  │        │  │ Port: 8080 │  │     │
│  │  └────────────┘  │        │  └────────────┘  │     │
│  │                  │        │                  │     │
│  │  LoadBalancer    │        │  LoadBalancer    │     │
│  │  → Port 8081     │        │  → Port 8082     │     │
│  └──────────────────┘        └──────────────────┘     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ ArgoCD (Opcional - Cluster 1)                   │   │
│  │ Dashboard: localhost:8080                        │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 🔌 Networking

### Comunicación entre Clusters

**Local (k3d)**:
- Cada cluster tiene su propio LoadBalancer (Traefik incluido en K3s)
- Service A obtiene IP del LoadBalancer de cluster2
- Comunicación vía HTTP usando IPs locales

**Cloud (VMs)**:
- Cada cluster K3s en VM diferente
- LoadBalancers con IPs públicas
- Comunicación vía HTTP entre IPs públicas

### Puertos Expuestos

| Componente | Puerto Local | Puerto Container |
|------------|--------------|------------------|
| Cluster1 API | 6550 | 6443 |
| Cluster2 API | 6551 | 6443 |
| Service A LB | 8081 | 80 → 8080 |
| Service B LB | 8082 | 80 → 8080 |
| ArgoCD UI | 8080 | 443 |

## 🐳 Imágenes Docker

### Service A (Python)
```dockerfile
Base: python:3.11-slim
Size: ~150MB
Dependencies: Flask, requests
```

### Service B (Node.js)
```dockerfile
Base: node:18-alpine
Size: ~120MB
Dependencies: express
```

## 🔄 Flujo de Despliegue

### Desarrollo Local
```bash
1. Construir imágenes: make build-images
2. Cargar en clusters: make load-images
3. Desplegar: make deploy-services
4. Probar: make test
```

### Actualización de Servicios
```bash
1. Modificar código
2. make build-images
3. make load-images
4. kubectl rollout restart deployment/service-a -n default
```

## 🌐 Migración a Cloud

### AWS EC2 + GCP Compute Engine

```bash
# 1. Crear VMs (Ubuntu 22.04)
# AWS: t2.micro (1vCPU, 1GB RAM)
# GCP: e2-micro (0.25-2vCPU, 1GB RAM)

# 2. Instalar K3s en cada VM
ssh user@aws-vm
curl -sfL https://get.k3s.io | sh -

ssh user@gcp-vm
curl -sfL https://get.k3s.io | sh -

# 3. Copiar kubeconfigs
scp user@aws-vm:/etc/rancher/k3s/k3s.yaml ~/.kube/aws-config
scp user@gcp-vm:/etc/rancher/k3s/k3s.yaml ~/.kube/gcp-config

# 4. Editar kubeconfigs (cambiar server: https://127.0.0.1:6443 por IP pública)
# AWS: https://<aws-public-ip>:6443
# GCP: https://<gcp-public-ip>:6443

# 5. Merge contexts
export KUBECONFIG=~/.kube/aws-config:~/.kube/gcp-config:~/.kube/config
kubectl config view --flatten > ~/.kube/config-merged
mv ~/.kube/config-merged ~/.kube/config

# 6. Construir y subir imágenes
docker build -t your-registry/service-a:latest services/service-a/
docker build -t your-registry/service-b:latest services/service-b/
docker push your-registry/service-a:latest
docker push your-registry/service-b:latest

# 7. Actualizar manifiestos (cambiar imagePullPolicy e image)
# deployment.yaml:
#   imagePullPolicy: Always
#   image: your-registry/service-a:latest

# 8. Desplegar
kubectl --context=aws-cluster apply -f services/service-a/k8s/
kubectl --context=gcp-cluster apply -f services/service-b/k8s/

# 9. Obtener IPs públicas
kubectl --context=gcp-cluster get svc service-b

# 10. Actualizar SERVICE_B_URL en cluster AWS
kubectl --context=aws-cluster set env deployment/service-a \
  SERVICE_B_URL=http://<gcp-service-b-ip>:80
```

## 🔐 Seguridad

### Consideraciones

1. **Secrets**: Usar Kubernetes Secrets para credenciales
2. **Network Policies**: Restringir tráfico entre pods
3. **TLS**: Usar cert-manager para HTTPS en producción
4. **RBAC**: Configurar roles apropiados
5. **Image Scanning**: Escanear imágenes con Trivy

### Para Producción
```bash
# Instalar cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Network Policies
kubectl apply -f manifests/network-policies/
```

## 📊 Monitoring (Opcional)

### Prometheus + Grafana

```bash
# Instalar Prometheus Stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

# Acceder a Grafana
kubectl port-forward svc/prometheus-grafana 3000:80
# user: admin, pass: prom-operator
```

## 🐛 Troubleshooting

### Cluster no inicia
```bash
k3d cluster list
k3d cluster delete cluster1
k3d cluster delete cluster2
make create-clusters
```

### Imágenes no se cargan
```bash
docker images | grep service-
k3d image import service-a:latest -c cluster1 --verbose
```

### Service no responde
```bash
kubectl get pods -A
kubectl logs -l app=service-a --tail=50
kubectl describe pod -l app=service-a
```

### LoadBalancer pending
```bash
# k3d incluye Traefik como LB por defecto
kubectl get svc -A
# Si está pending, espera 30 segundos

# Verificar Traefik
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
```

## 📖 Referencias

- [K3s Documentation](https://docs.k3s.io/)
- [k3d Documentation](https://k3d.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
