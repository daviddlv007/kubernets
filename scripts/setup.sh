#!/bin/bash

cd "$(dirname "$0")/.."

echo "🔧 Verificando dependencias..."
command -v docker >/dev/null || { echo "❌ Instalar Docker"; exit 1; }
command -v kubectl >/dev/null || { echo "❌ Instalar kubectl"; exit 1; }
command -v k3d >/dev/null || { echo "❌ Instalar k3d"; exit 1; }
echo "✅ Dependencias OK"

echo "🧹 Limpiando..."
k3d cluster delete cluster-a 2>/dev/null || true
k3d cluster delete cluster-b 2>/dev/null || true
sleep 3

echo "🏗️ Creando clusters..."
k3d cluster create cluster-a --agents 0 -p "30080:30080@server:0" --wait || exit 1
k3d cluster create cluster-b --agents 0 -p "30081:30081@server:0" --wait || exit 1

echo "🐳 Construyendo..."
docker build -t service-a:latest services/service-a/ || exit 1
docker build -t service-b:latest services/service-b/ || exit 1

echo "📤 Cargando imágenes..."
k3d image import service-a:latest -c cluster-a || exit 1
k3d image import service-b:latest -c cluster-b || exit 1

echo "🚀 Desplegando..."
sleep 5
kubectl apply -f services/service-a/k8s/ --context k3d-cluster-a || exit 1
kubectl apply -f services/service-b/k8s/ --context k3d-cluster-b || exit 1

echo "⏳ Esperando 30s..."
sleep 30

echo "📊 Estado:"
kubectl get pods --context k3d-cluster-a
kubectl get pods --context k3d-cluster-b

echo ""
echo "🧪 Probando:"
curl -s http://localhost:30080/health
echo ""
curl -s http://localhost:30081/health

echo ""
echo "✅ COMPLETADO"
