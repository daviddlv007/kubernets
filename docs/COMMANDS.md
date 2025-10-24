# 🎯 Guía de Comandos Esenciales

Referencia rápida de los comandos más utilizados.

## 🚀 Setup Inicial

```bash
# Verificar prerequisitos
make check-deps

# Instalar herramientas (si faltan)
make install-tools

# Setup completo automático
make setup

# O paso a paso:
make create-clusters     # Crear clusters
make install-argocd      # Instalar ArgoCD (opcional)
make deploy-services     # Desplegar servicios
make test               # Probar comunicación
```

---

## 📊 Monitoreo y Estado

```bash
# Ver estado general
make status

# Ver contextos disponibles
kubectl config get-contexts

# Cambiar de contexto
kubectl config use-context k3d-cluster1
kubectl config use-context k3d-cluster2

# Ver todos los recursos
kubectl get all
kubectl get all --all-namespaces

# Ver pods en ambos clusters
kubectl --context=k3d-cluster1 get pods
kubectl --context=k3d-cluster2 get pods

# Ver servicios y sus IPs
kubectl --context=k3d-cluster1 get svc
kubectl --context=k3d-cluster2 get svc

# Ver logs en tiempo real
make logs-service-a
make logs-service-b

# O directamente
kubectl --context=k3d-cluster1 logs -f -l app=service-a
kubectl --context=k3d-cluster2 logs -f -l app=service-b
```

---

## 🔄 Desarrollo y Updates

```bash
# Reconstruir imágenes
make build-images

# Cargar en clusters
make load-images

# Redesplegar servicios
make deploy-services

# O todo en uno
make build-images load-images deploy-services

# Reiniciar un deployment (sin rebuildar)
kubectl --context=k3d-cluster1 rollout restart deployment/service-a
kubectl --context=k3d-cluster2 rollout restart deployment/service-b

# Ver estado del rollout
kubectl --context=k3d-cluster1 rollout status deployment/service-a

# Ver historial de rollouts
kubectl --context=k3d-cluster1 rollout history deployment/service-a

# Rollback a versión anterior
kubectl --context=k3d-cluster1 rollout undo deployment/service-a
```

---

## 🧪 Testing y Debug

```bash
# Probar comunicación multi-cluster
make test

# Probar servicios manualmente
# 1. Obtener IPs
SERVICE_A_IP=$(kubectl --context=k3d-cluster1 get svc service-a -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
SERVICE_B_IP=$(kubectl --context=k3d-cluster2 get svc service-b -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# 2. Probar Service B directamente
curl http://$SERVICE_B_IP/hello
curl http://$SERVICE_B_IP/health

# 3. Probar Service A (llama a B)
curl http://$SERVICE_A_IP/call
curl http://$SERVICE_A_IP/health

# Debug dentro de un pod
kubectl --context=k3d-cluster1 exec -it deployment/service-a -- /bin/sh

# Ver eventos recientes
kubectl --context=k3d-cluster1 get events --sort-by='.lastTimestamp'

# Describir un recurso (muy útil para debugging)
kubectl --context=k3d-cluster1 describe pod -l app=service-a
kubectl --context=k3d-cluster1 describe svc service-a
kubectl --context=k3d-cluster1 describe deployment service-a

# Port forwarding para debug local
kubectl --context=k3d-cluster1 port-forward deployment/service-a 8080:8080
# Ahora puedes acceder en http://localhost:8080
```

---

## ⚙️ Configuración y Variables

```bash
# Ver variables de entorno de un pod
kubectl --context=k3d-cluster1 exec deployment/service-a -- env

# Actualizar variable de entorno
kubectl --context=k3d-cluster1 set env deployment/service-a SERVICE_B_URL=http://new-url

# Ver configuración actual del deployment
kubectl --context=k3d-cluster1 get deployment service-a -o yaml

# Editar deployment en vivo (no recomendado, usa YAML)
kubectl --context=k3d-cluster1 edit deployment service-a

# Aplicar cambios desde archivo
kubectl --context=k3d-cluster1 apply -f services/service-a/k8s/deployment.yaml

# Ver diferencias antes de aplicar
kubectl --context=k3d-cluster1 diff -f services/service-a/k8s/deployment.yaml
```

---

## 📈 Escalado

```bash
# Escalar manualmente
kubectl --context=k3d-cluster1 scale deployment service-a --replicas=3

# Ver réplicas
kubectl --context=k3d-cluster1 get deployment service-a

# Auto-escalar (HPA - requiere metrics-server)
kubectl --context=k3d-cluster1 autoscale deployment service-a --min=2 --max=5 --cpu-percent=80
```

---

## 🎯 ArgoCD

```bash
# Ver password de admin
make argocd-password

# Abrir UI
make argocd-ui
# Usuario: admin
# Password: (ver con comando anterior)

# CLI - Login
argocd login localhost:8080

# Listar aplicaciones
argocd app list

# Ver estado de una app
argocd app get service-a

# Sincronizar manualmente
argocd app sync service-a

# Agregar cluster
argocd cluster add k3d-cluster2

# Listar clusters
argocd cluster list
```

---

## 🐳 Docker y Imágenes

```bash
# Ver imágenes locales
docker images | grep service

# Construir imagen manualmente
docker build -t service-a:latest services/service-a/
docker build -t service-b:latest services/service-b/

# Cargar imagen en cluster k3d
k3d image import service-a:latest -c cluster1
k3d image import service-b:latest -c cluster2

# Ver imágenes en el cluster
kubectl --context=k3d-cluster1 get pods -o jsonpath='{.items[*].spec.containers[*].image}'

# Limpiar imágenes no usadas
docker image prune -a
```

---

## 🗑️ Limpieza

```bash
# Eliminar deployments
kubectl --context=k3d-cluster1 delete deployment service-a
kubectl --context=k3d-cluster2 delete deployment service-b

# Eliminar servicios
kubectl --context=k3d-cluster1 delete svc service-a
kubectl --context=k3d-cluster2 delete svc service-b

# Eliminar todo de un namespace
kubectl --context=k3d-cluster1 delete all --all

# Eliminar clusters
make delete-clusters

# O manualmente
k3d cluster delete cluster1
k3d cluster delete cluster2

# Limpiar Docker completo (¡cuidado!)
docker system prune -a --volumes
```

---

## 🔍 Información del Sistema

```bash
# Ver versiones
docker --version
kubectl version --client
k3d version

# Ver clusters k3d
k3d cluster list

# Ver nodes del cluster
kubectl --context=k3d-cluster1 get nodes -o wide
kubectl --context=k3d-cluster2 get nodes -o wide

# Ver uso de recursos (requiere metrics-server)
kubectl --context=k3d-cluster1 top nodes
kubectl --context=k3d-cluster1 top pods

# Ver capacidad del cluster
kubectl --context=k3d-cluster1 describe node

# Ver todas las APIs disponibles
kubectl api-resources

# Ver versión del cluster
kubectl --context=k3d-cluster1 version
```

---

## 📝 Logs y Debugging Avanzado

```bash
# Logs de múltiples pods
kubectl --context=k3d-cluster1 logs -l app=service-a --all-containers=true

# Logs con timestamp
kubectl --context=k3d-cluster1 logs -l app=service-a --timestamps=true

# Últimas N líneas
kubectl --context=k3d-cluster1 logs -l app=service-a --tail=100

# Logs desde hace X tiempo
kubectl --context=k3d-cluster1 logs -l app=service-a --since=1h

# Logs de contenedor anterior (si crasheó)
kubectl --context=k3d-cluster1 logs -l app=service-a --previous

# Stream de logs de múltiples pods
stern service-a --context k3d-cluster1  # requiere stern

# Ver eventos en tiempo real
kubectl --context=k3d-cluster1 get events --watch

# Debug de networking
kubectl --context=k3d-cluster1 run -it --rm debug --image=nicolaka/netshoot --restart=Never -- /bin/bash
# Dentro del pod:
# curl http://service-a
# nslookup service-a
# ping service-a
```

---

## 🎓 Helpers Útiles

```bash
# Alias para kubectl (agregar a ~/.bashrc o ~/.zshrc)
alias k=kubectl
alias kc1='kubectl --context=k3d-cluster1'
alias kc2='kubectl --context=k3d-cluster2'

# Autocompletado
source <(kubectl completion bash)  # bash
source <(kubectl completion zsh)   # zsh

# Ver YAML de cualquier recurso
kubectl --context=k3d-cluster1 get deployment service-a -o yaml
kubectl --context=k3d-cluster1 get pod <pod-name> -o yaml

# Extraer valores específicos con jsonpath
kubectl --context=k3d-cluster1 get pods -o jsonpath='{.items[*].metadata.name}'
kubectl --context=k3d-cluster1 get svc service-a -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Watch (actualización continua)
watch kubectl --context=k3d-cluster1 get pods
kubectl --context=k3d-cluster1 get pods --watch
```

---

## 🆘 Troubleshooting Rápido

```bash
# Cluster no responde
k3d cluster list
k3d cluster stop cluster1
k3d cluster start cluster1

# Pod en CrashLoopBackOff
kubectl --context=k3d-cluster1 describe pod <pod-name>
kubectl --context=k3d-cluster1 logs <pod-name> --previous

# Service no tiene IP externa
kubectl --context=k3d-cluster1 get svc service-a
# Esperar 30 segundos, k3d asigna IPs automáticamente

# Imagen no se encuentra
docker images | grep service-a
k3d image import service-a:latest -c cluster1 --verbose

# Cannot connect to cluster
kubectl config get-contexts
kubectl config use-context k3d-cluster1
k3d cluster list

# Reset completo
make clean
docker system prune -a
make setup
```

---

## 📚 Comandos de Ayuda

```bash
# Help de Makefile
make help

# Help de kubectl
kubectl --help
kubectl get --help
kubectl describe --help

# Explicar recurso
kubectl explain pod
kubectl explain pod.spec
kubectl explain deployment.spec.template.spec.containers

# Versión y cluster info
kubectl version
kubectl cluster-info
kubectl cluster-info dump
```

---

## 💾 Backup y Restore

```bash
# Exportar todos los recursos
kubectl --context=k3d-cluster1 get all -o yaml > backup-cluster1.yaml

# Exportar namespace específico
kubectl --context=k3d-cluster1 get all -n default -o yaml > backup-default.yaml

# Restaurar
kubectl --context=k3d-cluster1 apply -f backup-cluster1.yaml

# Backup de configuración
kubectl config view > kubeconfig-backup.yaml
```

---

Este es tu cheatsheet. ¡Guárdalo para referencia rápida! 📖
