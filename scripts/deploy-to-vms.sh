#!/bin/bash

# Script para desplegar en múltiples VMs reales
# Este script automatiza el despliegue manual (sin ArgoCD)

set -e

echo "🚀 Despliegue Multi-Cloud a VMs Reales"
echo ""

# Configuración de VMs (EDITA ESTAS VARIABLES)
VM1_IP="your-vm1-ip"
VM2_IP="your-vm2-ip"
VM3_IP="your-vm3-ip"
VM4_IP="your-vm4-ip"
VM_USER="ubuntu"  # o root según tu caso

echo "📋 VMs configuradas:"
echo "  VM1 (Cluster1): $VM1_IP"
echo "  VM2 (Cluster2): $VM2_IP"
echo "  VM3 (Cluster3): $VM3_IP"
echo "  VM4 (Cluster4): $VM4_IP"
echo ""

# Función para setup de una VM
setup_vm() {
    local VM_IP=$1
    local VM_NAME=$2
    
    echo "🔧 Configurando $VM_NAME ($VM_IP)..."
    
    # Instalar K3s
    ssh $VM_USER@$VM_IP "curl -sfL https://get.k3s.io | sh -"
    
    # Obtener kubeconfig
    ssh $VM_USER@$VM_IP "sudo cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/${VM_NAME}-config
    
    # Reemplazar localhost con IP real
    sed -i "s/127.0.0.1/$VM_IP/g" ~/.kube/${VM_NAME}-config
    
    echo "✅ $VM_NAME configurado"
}

# Función para desplegar servicio
deploy_service() {
    local CONTEXT=$1
    local SERVICE_PATH=$2
    local SERVICE_NAME=$3
    
    echo "📦 Desplegando $SERVICE_NAME en $CONTEXT..."
    kubectl --context=$CONTEXT apply -f $SERVICE_PATH
    echo "✅ $SERVICE_NAME desplegado"
}

# Menú de opciones
echo "Selecciona una opción:"
echo "1. Setup inicial de todas las VMs"
echo "2. Desplegar servicios a todas las VMs"
echo "3. Actualizar un servicio específico"
echo "4. Ver estado de todos los clusters"
echo ""
read -p "Opción: " OPTION

case $OPTION in
    1)
        echo "🏗️  Iniciando setup de VMs..."
        setup_vm $VM1_IP "vm1"
        setup_vm $VM2_IP "vm2"
        setup_vm $VM3_IP "vm3"
        setup_vm $VM4_IP "vm4"
        
        # Merge configs
        export KUBECONFIG=~/.kube/config:~/.kube/vm1-config:~/.kube/vm2-config:~/.kube/vm3-config:~/.kube/vm4-config
        kubectl config view --flatten > ~/.kube/config-all
        mv ~/.kube/config-all ~/.kube/config
        
        echo "✅ Setup completo! Contextos disponibles:"
        kubectl config get-contexts
        ;;
        
    2)
        echo "🚀 Desplegando servicios..."
        deploy_service "default" "services/service-a/k8s/" "Service A (VM1)"
        deploy_service "vm2-context" "services/service-b/k8s/" "Service B (VM2)"
        # Agregar más según necesites
        echo "✅ Todos los servicios desplegados"
        ;;
        
    3)
        read -p "¿Qué servicio? (a/b/c/d): " SERVICE
        read -p "¿En qué VM? (1/2/3/4): " VM
        
        case $SERVICE in
            a) SERVICE_PATH="services/service-a/k8s/" ;;
            b) SERVICE_PATH="services/service-b/k8s/" ;;
            c) SERVICE_PATH="services/service-c/k8s/" ;;
            d) SERVICE_PATH="services/service-d/k8s/" ;;
        esac
        
        CONTEXT="vm${VM}-context"
        kubectl --context=$CONTEXT apply -f $SERVICE_PATH
        echo "✅ Servicio actualizado"
        ;;
        
    4)
        echo "📊 Estado de todos los clusters:"
        for i in 1 2 3 4; do
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "VM$i:"
            kubectl --context=vm${i}-context get pods,svc 2>/dev/null || echo "Cluster no configurado"
        done
        ;;
        
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "🎉 Operación completada!"
