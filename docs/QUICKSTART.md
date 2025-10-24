# ⚡ Quick Start - 5 Minutos

Guía ultra-rápida para tener todo funcionando.

## 📋 Prerequisitos

```bash
# Verificar que tienes:
docker --version    # Docker 20.10+
kubectl version     # kubectl 1.25+
k3d version        # k3d 5.0+

# Si falta algo:
make install-tools
```

---

## 🚀 Setup Completo (Automático)

```bash
# Opción 1: Todo en un comando
make setup

# Espera 3-5 minutos...
# ✅ Listo!
```

---

## 🔧 Setup Manual (Paso a Paso)

### 1. Verificar dependencias
```bash
make check-deps
```

### 2. Crear clusters
```bash
make create-clusters
# Espera ~1 minuto
```

### 3. Instalar ArgoCD (opcional)
```bash
make install-argocd
# Espera ~2 minutos
```

### 4. Desplegar servicios
```bash
make deploy-services
# Espera ~2 minutos
```

### 5. Probar comunicación
```bash
make test
```

---

## ✅ Verificación

Deberías ver algo como:

```
🎉 ¡Comunicación multi-cluster exitosa!

📋 URLs de acceso:
  Service A: http://172.18.0.5:80
  Service B: http://172.18.0.6:80

🔍 Prueba manualmente:
  curl http://172.18.0.5:80/call
  curl http://172.18.0.6:80/hello
```

---

## 🧪 Probar Manualmente

```bash
# Ver estado
make status

# Obtener IPs
kubectl --context=k3d-cluster1 get svc service-a
kubectl --context=k3d-cluster2 get svc service-b

# Llamar a Service B directamente
curl http://<service-b-ip>/hello

# Llamar a Service A (llama a Service B)
curl http://<service-a-ip>/call
```

---

## 🎯 Comandos Útiles

```bash
# Ver todos los comandos
make help

# Ver logs en tiempo real
make logs-service-a   # Terminal 1
make logs-service-b   # Terminal 2

# Ver ArgoCD dashboard
make argocd-ui

# Reiniciar todo
make clean
make setup
```

---

## 🐛 Problemas Comunes

### "k3d: command not found"
```bash
make install-tools
```

### "Cluster creation failed"
```bash
# Limpiar Docker
docker system prune -a
make create-clusters
```

### "Pods not ready"
```bash
# Ver qué pasa
kubectl --context=k3d-cluster1 get pods
kubectl --context=k3d-cluster1 describe pod <pod-name>
kubectl --context=k3d-cluster1 logs <pod-name>
```

### "Connection refused"
```bash
# Esperar un poco más
sleep 30
make test

# Verificar LoadBalancers
kubectl --context=k3d-cluster1 get svc
kubectl --context=k3d-cluster2 get svc
```

---

## 📖 Siguiente Paso

Una vez que todo funcione:

1. **Explora el código**: Ve a `services/service-a/app.py` y `services/service-b/server.js`
2. **Modifica algo**: Cambia el mensaje de respuesta
3. **Reconstruye**: `make deploy-services`
4. **Prueba**: `make test`

**Para migrar a cloud**: Lee `docs/CLOUD_DEPLOYMENT.md`

---

## 🎓 ¿Qué acabas de crear?

```
✅ 2 clusters Kubernetes independientes (simulando multi-cloud)
✅ 2 microservicios (Python + Node.js)
✅ Comunicación HTTP entre clusters
✅ LoadBalancers funcionales
✅ Health checks y probes
✅ (Opcional) GitOps con ArgoCD
```

**¡Felicidades!** 🎉 Ahora tienes una arquitectura multi-cluster funcional.

---

## 🧹 Limpiar Todo

```bash
# Eliminar clusters
make delete-clusters

# Limpiar imágenes Docker
docker image prune -a
```

---

## 💡 Tips

- **Docker Desktop**: Asigna al menos 4GB RAM
- **Logs**: Usa `make logs-service-a` para debugging
- **Contextos**: `kubectl config get-contexts` para ver clusters
- **Switch context**: `kubectl config use-context k3d-cluster1`
