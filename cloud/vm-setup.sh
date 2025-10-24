#!/bin/bash

# Script de setup para VM en cualquier cloud provider
# Ejecutar como root en Ubuntu 22.04+

set -e

echo "🚀 K3s Multi-Cloud Setup Script"
echo "================================"
echo ""

# Detectar si estamos en root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Por favor ejecuta como root: sudo bash $0"
    exit 1
fi

# Actualizar sistema
echo "📦 Actualizando sistema..."
apt-get update -qq
apt-get upgrade -y -qq

# Instalar dependencias
echo "📦 Instalando dependencias..."
apt-get install -y -qq \
    curl \
    wget \
    git \
    jq \
    ufw

# Configurar firewall (UFW)
echo "🔥 Configurando firewall..."
ufw --force enable
ufw allow 22/tcp comment 'SSH'
ufw allow 6443/tcp comment 'K8s API'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 10250/tcp comment 'Kubelet'

echo "✅ Firewall configurado"

# Instalar K3s
echo "📦 Instalando K3s..."
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode 644 \
    --disable traefik

# Esperar a que K3s esté listo
echo "⏳ Esperando a que K3s inicie..."
sleep 10

# Verificar instalación
if kubectl get nodes &>/dev/null; then
    echo "✅ K3s instalado correctamente"
    kubectl get nodes
else
    echo "❌ Error en la instalación de K3s"
    exit 1
fi

# Instalar Traefik como LoadBalancer
echo "📦 Instalando Traefik LoadBalancer..."
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml

# Información final
echo ""
echo "🎉 ¡Setup completado!"
echo ""
echo "📋 Información importante:"
echo "=========================="
echo ""
echo "1. Kubeconfig location: /etc/rancher/k3s/k3s.yaml"
echo ""
echo "2. Para acceder desde tu laptop, ejecuta:"
echo "   scp root@$(hostname -I | awk '{print $1}'):/etc/rancher/k3s/k3s.yaml ~/.kube/cloud-cluster"
echo ""
echo "3. Edita el archivo descargado:"
echo "   sed -i 's/127.0.0.1/$(hostname -I | awk '{print $1}')/g' ~/.kube/cloud-cluster"
echo ""
echo "4. Merge con tu kubeconfig local:"
echo "   export KUBECONFIG=~/.kube/config:~/.kube/cloud-cluster"
echo "   kubectl config view --flatten > ~/.kube/config-merged"
echo "   mv ~/.kube/config-merged ~/.kube/config"
echo ""
echo "5. Verificar conexión:"
echo "   kubectl --context=default get nodes"
echo ""
echo "📝 Notas:"
echo "- Firewall UFW está activo con puertos necesarios abiertos"
echo "- K3s corre como servicio: systemctl status k3s"
echo "- Logs: journalctl -u k3s -f"
echo ""
