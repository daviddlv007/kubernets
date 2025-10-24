#!/bin/bash
# Script para construir y subir imágenes a GitHub Container Registry (GHCR)

set -e

GITHUB_USER="daviddlv007"
REGISTRY="ghcr.io"

echo "🔐 Haciendo login en GHCR..."
./scripts/ghcr-login.sh

echo ""
echo "🏗️  Construyendo Service A..."
docker build -t ${REGISTRY}/${GITHUB_USER}/service-a:latest services/service-a/

echo ""
echo "🏗️  Construyendo Service B..."
docker build -t ${REGISTRY}/${GITHUB_USER}/service-b:latest services/service-b/

echo ""
echo "📤 Subiendo Service A a GHCR..."
docker push ${REGISTRY}/${GITHUB_USER}/service-a:latest

echo ""
echo "📤 Subiendo Service B a GHCR..."
docker push ${REGISTRY}/${GITHUB_USER}/service-b:latest

echo ""
echo "✅ Imágenes publicadas exitosamente!"
echo ""

# Hacer las imágenes públicas automáticamente
echo "🌐 Haciendo imágenes públicas..."

# Obtener token de archivo seguro
if [ -f ~/.ghcr_token ]; then
    GITHUB_TOKEN=$(cat ~/.ghcr_token)
    
    # Hacer service-a público
    echo "   - Haciendo service-a público..."
    curl -s -X PATCH \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/user/packages/container/service-a" \
      -d '{"visibility":"public"}' > /dev/null 2>&1

    # Hacer service-b público
    echo "   - Haciendo service-b público..."
    curl -s -X PATCH \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/user/packages/container/service-b" \
      -d '{"visibility":"public"}' > /dev/null 2>&1
else
    echo "⚠️  Saltando hacer imágenes públicas (archivo ~/.ghcr_token no encontrado)"
    echo "💡 Para hacerlas públicas automáticamente, guarda tu token en ~/.ghcr_token"
fi

echo ""
echo "✅ Todo listo! Imágenes públicas disponibles en:"
echo "   - ${REGISTRY}/${GITHUB_USER}/service-a:latest"
echo "   - ${REGISTRY}/${GITHUB_USER}/service-b:latest"
