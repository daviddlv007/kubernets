# 🌐 Despliegue en VMs Multi-Cloud - Guía Rápida

## 🎯 Arquitectura Final

```
┌──────────────────────────────────────────────────────────────┐
│                        GitHub Repo                            │
│              https://github.com/daviddlv007/kubernets         │
└────────────┬─────────────┬──────────────┬────────────────────┘
             │             │              │
    ┌────────▼─────┐  ┌───▼──────┐  ┌───▼──────┐  ┌───▼──────┐
    │ VM1 (AWS)    │  │VM2 (GCP) │  │VM3 (Azure)│  │ VM4 (DO) │
    │ K3s          │  │K3s       │  │K3s        │  │K3s       │
    │ GitOps ✓     │  │GitOps ✓  │  │GitOps ✓   │  │GitOps ✓  │
    │ Service A    │  │Service B │  │Service C  │  │Service D │
    └──────────────┘  └──────────┘  └───────────┘  └──────────┘
```

---

## 📋 Prerrequisitos (Por VM)

- ✅ Ubuntu/Debian Linux
- ✅ 2GB RAM mínimo
- ✅ Acceso SSH
- ✅ Puerto 6443 abierto (Kubernetes API)
- ✅ Puertos 80/443 abiertos (para servicios)

---

## 🚀 Setup Completo (5 minutos por VM)

### **PASO 1: Conectar a la VM**

```bash
ssh user@vm1-ip  # Repetir para vm2, vm3, vm4
```

---

### **PASO 2: Instalar K3s**

```bash
# Una sola línea
curl -sfL https://get.k3s.io | sh -

# Verificar instalación
sudo k3s kubectl get nodes
```

---

### **PASO 3: Clonar Repositorio**

```bash
# Clonar el repo
git clone https://github.com/daviddlv007/kubernets.git
cd kubernets
```

---

### **PASO 4: Setup GitOps**

```bash
# Para VM1 (despliega Service A)
./scripts/setup-vm-gitops.sh vm1

# Para VM2 (despliega Service B)
./scripts/setup-vm-gitops.sh vm2

# Para VM3 (despliega Service C)
./scripts/setup-vm-gitops.sh vm3

# Para VM4 (despliega Service D)
./scripts/setup-vm-gitops.sh vm4
```

---

### **PASO 5: Verificar**

```bash
# Ver servicio GitOps
sudo systemctl status gitops

# Ver logs en tiempo real
sudo journalctl -u gitops -f

# Ver pods desplegados
sudo k3s kubectl get pods
```

---

## ✅ ¡LISTO!

Ahora tienes:
- ✅ 4 VMs en diferentes clouds
- ✅ Cada VM con K3s + GitOps
- ✅ Despliegue automático desde GitHub
- ✅ Multi-cloud real funcionando

---

## 🎯 Workflow Diario

### **En tu laptop:**

```bash
# 1. Editar código
vim services/service-a/app.py

# 2. Build y push imagen
./scripts/build-and-push.sh

# 3. Actualizar manifest (si cambió versión)
vim services/service-a/k8s/deployment.yaml

# 4. Commit y push
git add .
git commit -m "Updated service A"
git push

# 5. ¡En 30 segundos las 4 VMs tienen el cambio! ✨
```

### **Ver despliegue en las VMs:**

```bash
# Conectar a cualquier VM
ssh user@vm1-ip

# Ver logs
sudo journalctl -u gitops -f

# Verás:
# 🔄 Verificando cambios...
# ✨ Cambios detectados! Aplicando...
# 📦 Desplegando service-a...
# ✅ Despliegue completado!
```

---

## 📊 Monitoreo

### Ver estado de todas las VMs

```bash
# Script helper (ejecutar desde laptop)
cat > check-all-vms.sh <<'EOF'
#!/bin/bash
VMS=("vm1-ip" "vm2-ip" "vm3-ip" "vm4-ip")
NAMES=("VM1-AWS" "VM2-GCP" "VM3-Azure" "VM4-DO")

for i in "${!VMS[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 ${NAMES[$i]} (${VMS[$i]})"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ssh user@${VMS[$i]} "sudo k3s kubectl get pods && echo '' && sudo systemctl is-active gitops"
    echo ""
done
EOF

chmod +x check-all-vms.sh
./check-all-vms.sh
```

---

## 🔧 Configuración Avanzada

### Cambiar servicio desplegado en una VM

Editar `scripts/setup-vm-gitops.sh`:

```bash
case "$VM_NAME" in
    vm1)
        SERVICES=("service-a" "service-b")  # Desplegar múltiples
        ;;
    ...
esac
```

### Cambiar intervalo de sincronización

Editar `scripts/setup-vm-gitops.sh`:

```bash
SYNC_INTERVAL=30  # Cambiar a 10, 60, 120, etc.
```

Luego en cada VM:

```bash
./scripts/setup-vm-gitops.sh vm1  # Re-ejecutar setup
```

---

## 🆘 Troubleshooting

### GitOps no sincroniza

```bash
# Ver logs detallados
sudo journalctl -u gitops -n 100

# Verificar conectividad a GitHub
curl -I https://github.com

# Reiniciar servicio
sudo systemctl restart gitops
```

### K3s no responde

```bash
# Ver estado de K3s
sudo systemctl status k3s

# Reiniciar K3s
sudo systemctl restart k3s

# Ver logs de K3s
sudo journalctl -u k3s -n 100
```

### Imagen no se descarga

```bash
# Las imágenes deben ser públicas en GHCR
# Verificar en: https://github.com/daviddlv007?tab=packages

# O hacer login en la VM
echo 'TU_TOKEN' > ~/.ghcr_token
cat ~/.ghcr_token | sudo k3s crictl login ghcr.io -u daviddlv007 --password-stdin
```

---

## 🎓 Ventajas de Este Enfoque

### vs Manual Deployment

| Aspecto | GitOps Automático | Manual |
|---------|-------------------|--------|
| Despliegue | 1 `git push` | 4 SSH + 4 kubectl apply |
| Tiempo | 30 segundos | 5-10 minutos |
| Errores | Imposible olvidar VM | Fácil olvidar una VM |
| Rollback | `git revert` + push | Tedioso en 4 VMs |
| Auditoría | Git history completo | Ninguna |

### vs CI/CD Complejo (Jenkins, GitLab CI)

| Aspecto | GitOps Simple | Jenkins/GitLab |
|---------|---------------|----------------|
| Setup | 5 min por VM | Horas de config |
| Recursos | ~5MB RAM | ~1GB+ RAM |
| Complejidad | 1 script bash | Pipelines complejos |
| Debugging | journalctl | Logs distribuidos |
| Mantenimiento | Cero | Actualizaciones constantes |

---

## 💡 Tips para Producción

### 1. Notificaciones

Agregar a `gitops.sh`:

```bash
if [ "$OLD_HASH" != "$NEW_HASH" ]; then
    # Notificar via Slack/Discord
    curl -X POST https://hooks.slack.com/... \
      -d "text=Desplegado en $VM_NAME: $(git log -1 --oneline)"
fi
```

### 2. Health Checks

```bash
# Verificar que el servicio responda después del deploy
if ! curl -f http://localhost:8080/health; then
    echo "❌ Health check falló, revirtiendo..."
    git checkout HEAD~1
    kubectl apply -f services/$service/k8s/
fi
```

### 3. Backup antes de desplegar

```bash
kubectl get all -o yaml > /tmp/backup-$(date +%s).yaml
```

---

## 📈 Escalabilidad

Este sistema escala a:
- ✅ **10 VMs:** Sin cambios
- ✅ **50 VMs:** Sin cambios
- ✅ **100 VMs:** Considerar cluster de VMs con ArgoCD

Para tu proyecto (4 VMs): **Perfecto y óptimo** ✨

---

## ✅ Checklist de Despliegue

**Por cada VM:**

- [ ] SSH funciona
- [ ] K3s instalado: `sudo k3s kubectl get nodes`
- [ ] Repo clonado: `cd kubernets`
- [ ] GitOps configurado: `./scripts/setup-vm-gitops.sh vmX`
- [ ] Servicio activo: `sudo systemctl is-active gitops`
- [ ] Pods corriendo: `sudo k3s kubectl get pods`
- [ ] Logs limpios: `sudo journalctl -u gitops -n 20`

**Verificación final:**

- [ ] Push a GitHub
- [ ] Esperar 30 segundos
- [ ] Verificar logs en cada VM muestran despliegue

---

## 🎯 Resumen

**Setup por VM:** 5 minutos
**Despliegues futuros:** 30 segundos automáticos
**Mantenimiento:** Cero
**Costo extra:** Cero
**Complejidad:** Mínima
**Funcionalidad:** GitOps completo

**Es lo más simple, minimalista y óptimo para 4 VMs** ✅
