#!/bin/bash

# Script simplificado para probar comunicación usando port-forward

set -e

echo "🧪 Probando comunicación entre servicios multi-cluster"
echo ""

# Verificar que los pods estén corriendo
echo "📍 Verificando estado de los servicios..."
kubectl --context=k3d-cluster1 get pods -l app=service-a 2>/dev/null || { echo "❌ Service A no está desplegado"; exit 1; }
kubectl --context=k3d-cluster2 get pods -l app=service-b 2>/dev/null || { echo "❌ Service B no está desplegado"; exit 1; }

echo "✅ Ambos servicios están desplegados"
echo ""

# En k3d, usamos host.k3d.internal para comunicación entre clusters
# En cloud real, esto sería la IP pública del LoadBalancer
echo "📍 Configurando comunicación multi-cluster..."
SERVICE_B_URL="http://host.k3d.internal:8082"
echo "✅ Service B URL: $SERVICE_B_URL (host.k3d.internal simula IP pública)"
echo ""

# Actualizar SERVICE_B_URL en Service A
# Nota: En un escenario real multi-cloud, esto sería una IP pública o DNS
echo "2️⃣  Actualizando URL de Service B en Service A..."
kubectl --context=k3d-cluster1 set env deployment/service-a SERVICE_B_URL="$SERVICE_B_URL" > /dev/null 2>&1
echo "✅ Variable de entorno actualizada"
echo "⏳ Esperando a que Service A se reinicie..."
sleep 15
kubectl --context=k3d-cluster1 wait --for=condition=ready pod -l app=service-a --timeout=60s > /dev/null 2>&1 || true
echo ""

# Iniciar port-forward en segundo plano para Service B
echo "🔌 Iniciando port-forward para Service B (puerto 8082)..."
kubectl --context=k3d-cluster2 port-forward svc/service-b 8082:80 > /dev/null 2>&1 &
PF_PID_B=$!
sleep 3

# Iniciar port-forward en segundo plano para Service A
echo "🔌 Iniciando port-forward para Service A (puerto 8081)..."
kubectl --context=k3d-cluster1 port-forward svc/service-a 8081:80 > /dev/null 2>&1 &
PF_PID_A=$!
sleep 3

# Función de limpieza
cleanup() {
    echo ""
    echo "🧹 Limpiando port-forwards..."
    kill $PF_PID_B $PF_PID_A 2>/dev/null || true
}
trap cleanup EXIT

echo ""

# Probar Service B directamente
echo "1️⃣  Probando Service B directamente..."
RESPONSE_B=$(curl -s http://localhost:8082/hello 2>/dev/null || echo "error")
if [[ "$RESPONSE_B" != "error" ]]; then
    echo "✅ Service B responde:"
    echo "$RESPONSE_B" | jq '.' 2>/dev/null || echo "$RESPONSE_B"
else
    echo "❌ Service B no responde"
    kubectl --context=k3d-cluster2 logs -l app=service-b --tail=20
    exit 1
fi

echo ""

# Probar Service A llamando a Service B
echo "3️⃣  Probando Service A → Service B (comunicación multi-cluster)..."
RESPONSE_A=$(curl -s http://localhost:8081/call 2>/dev/null || echo "error")
if [[ "$RESPONSE_A" != "error" ]]; then
    echo "✅ Service A llama exitosamente a Service B:"
    echo "$RESPONSE_A" | jq '.' 2>/dev/null || echo "$RESPONSE_A"
else
    echo "❌ Comunicación fallida"
    kubectl --context=k3d-cluster1 logs -l app=service-a --tail=20
    exit 1
fi

echo ""
echo "🎉 ¡Comunicación multi-cluster exitosa!"
echo ""
echo "📋 Para acceso manual (en otra terminal):"
echo "  kubectl --context=k3d-cluster1 port-forward svc/service-a 8081:80"
echo "  kubectl --context=k3d-cluster2 port-forward svc/service-b 8082:80"
echo ""
echo "  Luego:"
echo "  curl http://localhost:8081/call"
echo "  curl http://localhost:8082/hello"
