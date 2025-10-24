#!/bin/bash
# Script para instalar y configurar ArgoCD localmente

set -e

echo "🚀 Instalando ArgoCD en cluster local..."

# Crear namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Instalar ArgoCD
echo "📦 Descargando ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar a que esté listo
echo "⏳ Esperando a que ArgoCD esté listo..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Obtener password
echo ""
echo "✅ ArgoCD instalado correctamente!"
echo ""
echo "📝 Credenciales de acceso:"
echo "   Usuario: admin"
echo -n "   Password: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "🌐 Para acceder al dashboard:"
echo "   Ejecuta: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Abre: https://localhost:8080"
echo ""
echo "💡 Acepta el certificado autofirmado en el navegador"
