# Comandos principales para operar clusters k3d
.PHONY: start stop status logs clean setup

start: # Inicia ambos clusters si están detenidos
	k3d cluster start cluster-a || true
	k3d cluster start cluster-b || true

stop: # Detiene ambos clusters sin eliminarlos
	k3d cluster stop cluster-a || true
	k3d cluster stop cluster-b || true

status: # Muestra el estado de los pods en ambos clusters
	kubectl get pods --context k3d-cluster-a
	kubectl get pods --context k3d-cluster-b

logs: # Muestra los últimos 50 logs de ambos servicios
	kubectl logs --context k3d-cluster-a -l app=service-a --tail=50
	kubectl logs --context k3d-cluster-b -l app=service-b --tail=50

clean: # Elimina ambos clusters completamente
	bash scripts/cleanup.sh

setup: # Ejecuta el script de instalación completa y despliegue
	bash scripts/setup.sh
