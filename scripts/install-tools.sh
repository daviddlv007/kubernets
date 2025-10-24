#!/bin/bash

# Script de instalación de herramientas necesarias
# Detecta el sistema operativo e instala las dependencias

set -e

echo "🔧 Instalador de herramientas para Multi-Cloud K8s"
echo ""

# Detectar OS
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "Sistema detectado: $OS $ARCH"
echo ""

# Función para instalar kubectl
install_kubectl() {
    echo "📦 Instalando kubectl..."
    if [[ "$OS" == "Linux" ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    elif [[ "$OS" == "Darwin" ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    echo "✅ kubectl instalado"
}

# Función para instalar k3d
install_k3d() {
    echo "📦 Instalando k3d..."
    
    # Método directo: descargar binario
    K3D_VERSION="v5.6.0"
    
    if [[ "$OS" == "Linux" ]]; then
        curl -sL "https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64" -o k3d
    elif [[ "$OS" == "Darwin" ]]; then
        curl -sL "https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-darwin-amd64" -o k3d
    fi
    
    chmod +x k3d
    sudo mv k3d /usr/local/bin/k3d
    echo "✅ k3d instalado"
}

# Función para instalar Docker (solo Linux)
install_docker() {
    echo "📦 Instalando Docker..."
    if [[ "$OS" == "Linux" ]]; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        echo "✅ Docker instalado"
        echo "⚠️  Necesitas cerrar sesión y volver a entrar para usar Docker sin sudo"
    else
        echo "⚠️  Instala Docker Desktop manualmente desde https://www.docker.com/products/docker-desktop"
    fi
}

# Verificar e instalar herramientas
if ! command -v kubectl &> /dev/null; then
    install_kubectl
else
    echo "✅ kubectl ya está instalado ($(kubectl version --client --short 2>/dev/null || kubectl version --client))"
fi

if ! command -v k3d &> /dev/null; then
    install_k3d
else
    echo "✅ k3d ya está instalado ($(k3d version))"
fi

if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "✅ Docker ya está instalado ($(docker --version))"
fi

echo ""
echo "🎉 Instalación completada!"
echo ""
echo "Verifica las instalaciones con:"
echo "  docker --version"
echo "  kubectl version --client"
echo "  k3d version"
