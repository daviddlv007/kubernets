#!/bin/bash
# Script para login en GitHub Container Registry

# ⚠️ NUNCA subir este archivo a GitHub (está en .gitignore)
# El token debe estar en ~/.ghcr_token

GITHUB_USER="daviddlv007"

if [ ! -f ~/.ghcr_token ]; then
    echo "❌ Error: Archivo ~/.ghcr_token no encontrado"
    echo "💡 Ejecuta: echo 'TU_TOKEN' > ~/.ghcr_token"
    exit 1
fi

GITHUB_TOKEN=$(cat ~/.ghcr_token)

echo "🔐 Haciendo login en ghcr.io..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

if [ $? -eq 0 ]; then
    echo "✅ Login exitoso en GHCR"
else
    echo "❌ Error en login"
    exit 1
fi
