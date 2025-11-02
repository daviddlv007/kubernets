#!/bin/bash

cd "$(dirname "$0")/.."

echo "🧹 Limpiando clusters..."
k3d cluster delete cluster-a 2>/dev/null || true
k3d cluster delete cluster-b 2>/dev/null || true
echo "✅ Limpieza completada"
