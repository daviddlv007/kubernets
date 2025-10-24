# 🎯 ArgoCD Configuration

Este directorio contiene las configuraciones de ArgoCD para orquestar despliegues multi-cluster.

## 📁 Estructura

```
argocd/
├── install.sh              # Script de instalación
├── applications/           # Definiciones de aplicaciones
│   ├── service-a.yaml     # App para cluster1
│   └── service-b.yaml     # App para cluster2
└── README.md              # Este archivo
```

## 🚀 Uso

### Instalación
```bash
make install-argocd
```

### Acceder al Dashboard
```bash
make argocd-ui
# Usuario: admin
# Password: (se muestra en terminal)
```

## 📝 Notas

- ArgoCD se instala en cluster1 por defecto
- Puede gestionar múltiples clusters desde un solo punto
- GitOps: cambios en Git → despliegue automático
- Para usar ArgoCD Applications, necesitas un repositorio Git remoto

## 🔄 GitOps Workflow

1. Modificas manifiestos en Git
2. Haces commit y push
3. ArgoCD detecta cambios (polling cada 3min)
4. ArgoCD aplica cambios a los clusters

## 🎓 Para Proyecto Académico

**Opcional**: ArgoCD Applications requiere repositorio remoto.

Para este proyecto minimalista, usamos despliegue directo con `kubectl` (más simple).

Si quieres agregar GitOps completo:
1. Sube el proyecto a GitHub
2. Crea ArgoCD Applications apuntando a tu repo
3. ArgoCD sincronizará automáticamente
