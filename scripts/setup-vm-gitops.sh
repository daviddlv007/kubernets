#!/bin/bash
# Setup GitOps en VM específica con servicio asignado

set -e

# Configuración por VM
# Editar según tu arquitectura
VM_NAME="${1:-vm1}"

case "$VM_NAME" in
    vm1)
        SERVICES=("service-a")
        CLUSTER_CONTEXT="default"
        ;;
    vm2)
        SERVICES=("service-b")
        CLUSTER_CONTEXT="default"
        ;;
    vm3)
        SERVICES=("service-c")
        CLUSTER_CONTEXT="default"
        ;;
    vm4)
        SERVICES=("service-d")
        CLUSTER_CONTEXT="default"
        ;;
    *)
        echo "❌ VM desconocida: $VM_NAME"
        echo "💡 Uso: $0 [vm1|vm2|vm3|vm4]"
        exit 1
        ;;
esac

echo "🚀 Configurando GitOps para $VM_NAME"
echo "📦 Servicios: ${SERVICES[@]}"
echo ""

# Verificar K3s
if ! command -v k3s &> /dev/null; then
    echo "❌ K3s no instalado"
    echo "💡 Ejecuta: curl -sfL https://get.k3s.io | sh -"
    exit 1
fi

echo "✅ K3s encontrado"
echo ""

# Configurar kubectl
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config

echo "✅ kubectl configurado"
echo ""

# Desplegar servicios asignados a esta VM
echo "📦 Desplegando servicios..."
for service in "${SERVICES[@]}"; do
    if [ -d "services/$service/k8s" ]; then
        echo "  → Desplegando $service..."
        kubectl apply -f services/$service/k8s/
    else
        echo "  ⚠️  Directorio services/$service/k8s no encontrado"
    fi
done

echo ""
echo "✅ Servicios desplegados"
echo ""

# Crear archivo de configuración para GitOps
cat > /tmp/gitops-vm-config.sh <<EOF
# Configuración de VM
VM_NAME="$VM_NAME"
SERVICES="${SERVICES[@]}"
EOF

# Crear script GitOps personalizado
cat > /tmp/gitops-vm.sh <<'SCRIPT'
#!/bin/bash
# GitOps automático para VM específica

set -e

# Cargar configuración
source /tmp/gitops-vm-config.sh

REPO_URL="https://github.com/daviddlv007/kubernets.git"
REPO_DIR="/tmp/kubernets-gitops"
SYNC_INTERVAL=30

echo "🚀 GitOps Automático - $VM_NAME"
echo "📦 Servicios: $SERVICES"
echo "⏱️  Sincronización cada ${SYNC_INTERVAL}s"
echo ""

# Configurar kubectl
export KUBECONFIG=/home/ubuntu/.kube/config

# Clonar repo si no existe
if [ ! -d "$REPO_DIR" ]; then
    echo "📥 Clonando repositorio..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# Loop infinito de sincronización
while true; do
    echo "🔄 [$(date '+%H:%M:%S')] Verificando cambios..."
    
    OLD_HASH=$(git rev-parse HEAD)
    git pull --quiet origin main 2>/dev/null || {
        echo "⚠️  Error en git pull, reintentando..."
        sleep $SYNC_INTERVAL
        continue
    }
    NEW_HASH=$(git rev-parse HEAD)
    
    if [ "$OLD_HASH" != "$NEW_HASH" ]; then
        echo "✨ Cambios detectados! Aplicando..."
        
        # Desplegar solo los servicios asignados a esta VM
        for service in $SERVICES; do
            if [ -d "services/$service/k8s" ]; then
                echo "  📦 Desplegando $service..."
                kubectl apply -f services/$service/k8s/ 2>&1 | grep -v "unchanged" || true
            fi
        done
        
        echo "✅ Despliegue completado en $VM_NAME!"
        echo "📝 Último cambio:"
        git log -1 --oneline
        echo ""
    else
        echo "✓ Sin cambios"
    fi
    
    sleep $SYNC_INTERVAL
done
SCRIPT

chmod +x /tmp/gitops-vm.sh

# Crear servicio systemd
sudo tee /etc/systemd/system/gitops.service > /dev/null <<EOF
[Unit]
Description=GitOps Automático - $VM_NAME
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/kubernets
ExecStart=/tmp/gitops-vm.sh
Restart=always
RestartSec=10
Environment="KUBECONFIG=$HOME/.kube/config"

[Install]
WantedBy=multi-user.target
EOF

# Activar servicio
sudo systemctl daemon-reload
sudo systemctl enable gitops.service
sudo systemctl start gitops.service

echo ""
echo "✅ GitOps configurado para $VM_NAME!"
echo ""
echo "📊 Ver estado:"
echo "   sudo systemctl status gitops"
echo ""
echo "📝 Ver logs:"
echo "   sudo journalctl -u gitops -f"
echo ""
echo "🎯 Servicios desplegados: ${SERVICES[@]}"
