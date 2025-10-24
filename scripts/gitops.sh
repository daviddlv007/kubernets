#!/bin/bash
# GitOps automático minimalista - Sincroniza desde GitHub cada 30 segundos

set -e

REPO_URL="https://github.com/daviddlv007/kubernets.git"
REPO_DIR="/tmp/kubernets-gitops"
SYNC_INTERVAL=30

echo "🚀 GitOps Automático Iniciado"
echo "📦 Repo: $REPO_URL"
echo "⏱️  Sincronización cada ${SYNC_INTERVAL}s"
echo ""

# Clonar repo si no existe
if [ ! -d "$REPO_DIR" ]; then
    echo "📥 Clonando repositorio..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# Loop infinito de sincronización
while true; do
    echo "🔄 [$(date '+%H:%M:%S')] Verificando cambios..."
    
    # Guardar hash actual
    OLD_HASH=$(git rev-parse HEAD)
    
    # Pull cambios
    git pull --quiet origin main 2>/dev/null || {
        echo "⚠️  Error en git pull, reintentando en ${SYNC_INTERVAL}s..."
        sleep $SYNC_INTERVAL
        continue
    }
    
    # Verificar si hay cambios
    NEW_HASH=$(git rev-parse HEAD)
    
    if [ "$OLD_HASH" != "$NEW_HASH" ]; then
        echo "✨ Cambios detectados! Aplicando..."
        
        # Aplicar Service A (cluster1)
        if kubectl config use-context k3d-cluster1 2>/dev/null; then
            echo "  📦 Desplegando Service A en cluster1..."
            kubectl apply -f services/service-a/k8s/ 2>&1 | grep -v "unchanged" || true
        fi
        
        # Aplicar Service B (cluster2)
        if kubectl config use-context k3d-cluster2 2>/dev/null; then
            echo "  📦 Desplegando Service B en cluster2..."
            kubectl apply -f services/service-b/k8s/ 2>&1 | grep -v "unchanged" || true
        fi
        
        echo "✅ Despliegue completado!"
        
        # Mostrar último commit
        echo "📝 Último cambio:"
        git log -1 --oneline
        echo ""
    else
        echo "✓ Sin cambios"
    fi
    
    sleep $SYNC_INTERVAL
done
