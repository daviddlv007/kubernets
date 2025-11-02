RESUMEN FINAL
Lo que hemos logrado:

Estructura limpia de Kubernetes:

Archivos separados: deployment.yaml y service.yaml para cada servicio
Sin manifiestos all.yaml monolíticos
Script de limpieza (cleanup.sh):

Elimina ambos clusters en segundos
No toca las dependencias instaladas
Script maestro (setup.sh):

Verifica dependencias (Docker, kubectl, k3d)
Limpia automáticamente clusters existentes
Crea 2 clusters k3s independientes (cluster-a, cluster-b)
Construye imágenes Docker
Carga imágenes en cada cluster
Despliega servicios en clusters separados
Prueba comunicación HTTP entre servicios
Todo en un solo comando
Funcionamiento validado:

Service A corriendo en cluster-a: http://localhost:30080/health
Service B corriendo en cluster-b: http://localhost:30081/health
Ambos servicios respondiendo correctamente
Base lista para VMs reales: Esta configuración local es exactamente lo que necesitas para replicar en dos máquinas virtuales, donde cada cluster representará una VM en diferente proveedor cloud.