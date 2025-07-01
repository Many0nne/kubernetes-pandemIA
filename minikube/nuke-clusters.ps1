$namespaces = @("pandemia-us", "pandemia-fr", "pandemia-ch")

# Vérifie si Minikube est en cours d'exécution
$minikubeRunning = & minikube status | Select-String "host: Running"

if (-not $minikubeRunning) {
    Write-Host "Démarrage du cluster Minikube (unique)..."
    & minikube start
} else {
    Write-Host "Minikube est déjà en cours d'exécution. Aucun redémarrage nécessaire."
}

# Force le contexte Minikube
kubectl config use-context minikube

# Suppression des namespaces
foreach ($ns in $namespaces) {
    $nsExists = kubectl get namespace $ns --ignore-not-found
    if ($nsExists) {
        Write-Host "Suppression du namespace $ns..."
        kubectl delete namespace $ns
    } else {
        Write-Host "Namespace $ns non trouvé, rien à supprimer."
    }
}

# Nettoyage des images Docker locales dans Minikube
Write-Host "Suppression des images Docker locales inutilisées dans Minikube..."
minikube ssh -- "docker system prune -af"

Write-Host "`nToutes les ressources ont été supprimées et les images nettoyées."
