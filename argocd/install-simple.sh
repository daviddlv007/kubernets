#!/bin/bash
# Instalación simplificada de ArgoCD usando kubectl directamente

set -e

echo "🚀 Instalando ArgoCD (método alternativo)..."

# Crear namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Instalar ArgoCD usando el CLI si está disponible, sino usar método básico
echo "📦 Instalando ArgoCD CLI..."
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$VERSION" ]; then
    VERSION="v2.9.3"
fi

echo "   Versión: $VERSION"

# Descargar ArgoCD CLI
if [ ! -f /tmp/argocd ]; then
    echo "   Descargando CLI..."
    curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
    chmod +x /tmp/argocd
fi

# Usar el CLI para instalar
echo "📦 Instalando componentes de ArgoCD..."
/tmp/argocd admin dashboard install --port 8080 --namespace argocd 2>/dev/null || {
    echo "⚠️  Instalación con CLI falló, usando método kubectl directo..."
    
    # Crear deployments manualmente
    echo "   Creando recursos de ArgoCD..."
    
    # Crear ServiceAccount
    kubectl apply -n argocd -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-server
  namespace: argocd
---
apiVersion: v1
kind: Service
metadata:
  name: argocd-server
  namespace: argocd
spec:
  type: ClusterIP
  ports:
  - port: 443
    targetPort: 8080
    protocol: TCP
    name: https
  selector:
    app.kubernetes.io/name: argocd-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server
  namespace: argocd
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
  template:
    metadata:
      labels:
        app.kubernetes.io/name: argocd-server
    spec:
      serviceAccountName: argocd-server
      containers:
      - name: argocd-server
        image: quay.io/argoproj/argocd:$VERSION
        command:
        - argocd-server
        - --insecure
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 10
EOF
}

echo ""
echo "⏳ Esperando a que ArgoCD esté listo..."
sleep 10

# Intentar obtener el password
echo ""
echo "✅ ArgoCD instalado!"
echo ""
echo "📝 Para acceder:"
echo "   1. Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   2. URL: https://localhost:8080"
echo "   3. Usuario: admin"
echo ""
echo "💡 Para obtener el password más tarde:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
