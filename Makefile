.PHONY: help check-deps install-tools create-clusters delete-clusters install-argocd deploy-services test clean status

# Variables
CLUSTER1_NAME=cluster1
CLUSTER2_NAME=cluster2
CLUSTER1_PORT=6550
CLUSTER2_PORT=6551
ARGOCD_NAMESPACE=argocd

help: ## Mostrar ayuda
	@echo "🚀 Multi-Cloud Kubernetes - Comandos Disponibles"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

check-deps: ## Verificar dependencias instaladas
	@echo "🔍 Verificando dependencias..."
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker no instalado"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl no instalado"; exit 1; }
	@command -v k3d >/dev/null 2>&1 || { echo "❌ k3d no instalado"; exit 1; }
	@echo "✅ Todas las dependencias están instaladas"

install-tools: ## Instalar herramientas necesarias (Linux/macOS)
	@echo "📦 Instalando herramientas..."
	@bash scripts/install-tools.sh

create-clusters: ## Crear ambos clusters K3s
	@echo "🏗️  Creando clusters K3s..."
	@k3d cluster create $(CLUSTER1_NAME) \
		--api-port $(CLUSTER1_PORT) \
		--agents 0
	@k3d cluster create $(CLUSTER2_NAME) \
		--api-port $(CLUSTER2_PORT) \
		--agents 0
	@echo "✅ Clusters creados exitosamente"
	@kubectl config use-context k3d-$(CLUSTER1_NAME)
	@echo ""
	@echo "📋 Clusters disponibles:"
	@k3d cluster list

delete-clusters: ## Eliminar ambos clusters
	@echo "🗑️  Eliminando clusters..."
	@k3d cluster delete $(CLUSTER1_NAME) || true
	@k3d cluster delete $(CLUSTER2_NAME) || true
	@echo "✅ Clusters eliminados"

list-clusters: ## Listar clusters
	@k3d cluster list

install-argocd: ## Instalar ArgoCD en cluster1
	@echo "📦 Instalando ArgoCD..."
	@kubectl config use-context k3d-$(CLUSTER1_NAME)
	@kubectl create namespace $(ARGOCD_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@kubectl apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "⏳ Esperando a que ArgoCD esté listo..."
	@kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $(ARGOCD_NAMESPACE)
	@echo "✅ ArgoCD instalado exitosamente"
	@echo ""
	@echo "🔐 Password de admin:"
	@kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
	@echo ""
	@echo "🌐 Para acceder al dashboard ejecuta: make argocd-ui"

argocd-ui: ## Abrir ArgoCD Dashboard
	@echo "🌐 Abriendo ArgoCD en http://localhost:8080"
	@echo "👤 Usuario: admin"
	@echo "🔐 Password:"
	@kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
	@echo ""
	@kubectl config use-context k3d-$(CLUSTER1_NAME)
	@kubectl port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8080:443

argocd-password: ## Mostrar password de ArgoCD
	@kubectl config use-context k3d-$(CLUSTER1_NAME)
	@kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

build-images: ## Construir imágenes Docker de los servicios
	@echo "🐳 Construyendo imágenes..."
	@docker build -t service-a:latest services/service-a/
	@docker build -t service-b:latest services/service-b/
	@echo "✅ Imágenes construidas"

load-images: build-images ## Cargar imágenes en clusters k3d
	@echo "📤 Cargando imágenes en clusters..."
	@k3d image import service-a:latest -c $(CLUSTER1_NAME)
	@k3d image import service-b:latest -c $(CLUSTER2_NAME)
	@echo "✅ Imágenes cargadas en clusters"

deploy-services: load-images ## Desplegar servicios en clusters
	@echo "🚀 Desplegando servicios..."
	@kubectl config use-context k3d-$(CLUSTER1_NAME)
	@kubectl apply -f services/service-a/k8s/
	@kubectl config use-context k3d-$(CLUSTER2_NAME)
	@kubectl apply -f services/service-b/k8s/
	@echo "✅ Servicios desplegados"
	@echo ""
	@echo "⏳ Esperando a que los pods estén listos..."
	@kubectl config use-context k3d-$(CLUSTER1_NAME)
	@kubectl wait --for=condition=ready pod -l app=service-a --timeout=120s || true
	@kubectl config use-context k3d-$(CLUSTER2_NAME)
	@kubectl wait --for=condition=ready pod -l app=service-b --timeout=120s || true
	@echo ""
	@make status

test: ## Probar comunicación entre servicios
	@echo "🧪 Probando comunicación entre servicios..."
	@bash scripts/test-final.sh

logs-service-a: ## Ver logs de Service A
	@kubectl config use-context k3d-$(CLUSTER1_NAME)
	@kubectl logs -l app=service-a --tail=50 -f

logs-service-b: ## Ver logs de Service B
	@kubectl config use-context k3d-$(CLUSTER2_NAME)
	@kubectl logs -l app=service-b --tail=50 -f

status: ## Ver estado de todos los recursos
	@echo "📊 Estado de Cluster 1 ($(CLUSTER1_NAME)):"
	@kubectl config use-context k3d-$(CLUSTER1_NAME)
	@kubectl get pods,svc
	@echo ""
	@echo "📊 Estado de Cluster 2 ($(CLUSTER2_NAME)):"
	@kubectl config use-context k3d-$(CLUSTER2_NAME)
	@kubectl get pods,svc

clean: delete-clusters ## Limpiar todo (clusters y recursos)
	@echo "🧹 Limpieza completa realizada"

# Quick setup completo
setup: check-deps create-clusters install-argocd deploy-services ## Setup completo (todo en uno)
	@echo ""
	@echo "✅ Setup completo finalizado!"
	@echo ""
	@echo "🎉 Siguiente paso: make test"
