#!/bin/bash

# Script para probar la comunicación entre Service A y Service B

set -e

echo "🧪 Probando comunicación entre servicios multi-cluster"
echo ""

# En k3d, los servicios son accesibles vía localhost con los puertos mapeados
echo "📍 Configurando acceso a servicios..."
SERVICE_B_URL="http://localhost:8082"
SERVICE_A_URL="http://localhost:8081"

echo "✅ Service B URL: $SERVICE_B_URL"
echo "✅ Service A URL: $SERVICE_A_URL"
echo ""

# Probar Service B directamente
echo "1️⃣  Probando Service B directamente (cluster2)..."
RESPONSE_B=$(curl -s $SERVICE_B_URL/hello || echo "error")
if [[ "$RESPONSE_B" != "error" ]]; then
    echo "✅ Service B responde:"
    echo "$RESPONSE_B" | jq '.' 2>/dev/null || echo "$RESPONSE_B"
else
    echo "❌ Service B no responde. Verificando pods..."
    kubectl get pods -l app=service-b
    exit 1
fi

echo ""

# Actualizar SERVICE_B_URL en Service A
echo ""
echo "2️⃣  Actualizando URL de Service B en Service A..."
kubectl config use-context k3d-cluster1 > /dev/null 2>&1
kubectl set env deployment/service-a SERVICE_B_URL="$SERVICE_B_URL" > /dev/null 2>&1
echo "✅ Variable de entorno actualizada"

# Esperar a que el pod se actualice
echo "⏳ Esperando a que Service A se reinicie..."
sleep 10
kubectl wait --for=condition=ready pod -l app=service-a --timeout=60s > /dev/null 2>&1 || true

echo ""

# Probar Service A llamando a Service B
echo "3️⃣  Probando Service A → Service B (comunicación multi-cluster)..."
RESPONSE_A=$(curl -s $SERVICE_A_URL/call || echo "error")
if [[ "$RESPONSE_A" != "error" ]]; then
    echo "✅ Service A llama exitosamente a Service B:"
    echo "$RESPONSE_A" | jq '.' 2>/dev/null || echo "$RESPONSE_A"
else
    echo "❌ Comunicación fallida. Verificando logs..."
    kubectl logs -l app=service-a --tail=20
    exit 1
fi

echo ""
echo "🎉 ¡Comunicación multi-cluster exitosa!"
echo ""
echo "📋 URLs de acceso:"
echo "  Service A: $SERVICE_A_URL"
echo "  Service B: $SERVICE_B_URL"
echo ""
echo "🔍 Prueba manualmente:"
echo "  curl $SERVICE_A_URL/call"
echo "  curl $SERVICE_B_URL/hello"
