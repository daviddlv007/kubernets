#!/bin/bash
# Setup GitOps automático como servicio systemd

set -e

echo "🚀 Configurando GitOps Automático"
echo ""

# Verificar que los clusters existen
echo "1️⃣  Verificando clusters..."
kubectl config use-context k3d-cluster1 >/dev/null 2>&1 || {
    echo "❌ Error: cluster1 no existe"
    echo "💡 Ejecuta: make create-clusters"
    exit 1
}

kubectl config use-context k3d-cluster2 >/dev/null 2>&1 || {
    echo "❌ Error: cluster2 no existe"
    echo "💡 Ejecuta: make create-clusters"
    exit 1
}

echo "   ✅ Clusters encontrados"
echo ""

# Desplegar servicios inicialmente
echo "2️⃣  Despliegue inicial..."
kubectl config use-context k3d-cluster1
kubectl apply -f services/service-a/k8s/
echo "   ✅ Service A desplegado en cluster1"

kubectl config use-context k3d-cluster2
kubectl apply -f services/service-b/k8s/
echo "   ✅ Service B desplegado en cluster2"
echo ""

# Configurar como servicio systemd
echo "3️⃣  Configurando servicio systemd..."

# Copiar el service file
sudo cp scripts/gitops.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Habilitar servicio para inicio automático
sudo systemctl enable gitops.service

# Iniciar servicio
sudo systemctl start gitops.service

echo "   ✅ Servicio configurado e iniciado"
echo ""

# Mostrar estado
echo "4️⃣  Estado del servicio:"
sudo systemctl status gitops.service --no-pager | head -15
echo ""

echo "✅ GitOps Automático configurado!"
echo ""
echo "📋 Comandos útiles:"
echo "   Ver logs:      sudo journalctl -u gitops -f"
echo "   Estado:        sudo systemctl status gitops"
echo "   Detener:       sudo systemctl stop gitops"
echo "   Reiniciar:     sudo systemctl restart gitops"
echo "   Deshabilitar:  sudo systemctl disable gitops"
echo ""
echo "🎯 Workflow desde ahora:"
echo "   1. Editas código localmente"
echo "   2. git add . && git commit -m 'mensaje'"
echo "   3. git push"
echo "   4. ¡El servicio despliega automáticamente en ~30s!"
