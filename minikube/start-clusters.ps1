$namespaces = @("pandemia-us", "pandemia-fr", "pandemia-ch")

# 1. Vérifie si Minikube est déjà en cours d'exécution
$minikubeRunning = & minikube status | Select-String "host: Running"

if (-not $minikubeRunning) {
    Write-Host "Démarrage du cluster Minikube (unique)..."
    & minikube start
} else {
    Write-Host "Minikube est déjà en cours d'exécution. Aucun redémarrage nécessaire."
}

# 2. Force le contexte Minikube
kubectl config use-context minikube

# Création des namespaces si besoin (sans gestion de secret)
foreach ($ns in $namespaces) {
    $nsExists = kubectl get namespace $ns --ignore-not-found
    if (-not $nsExists) {
        Write-Host "Création du namespace $ns..."
        kubectl create namespace $ns
    }
}

# 3. Déploiement
foreach ($ns in $namespaces) {
    $scriptPath = ".\$ns\$ns.ps1"
    if (Test-Path $scriptPath) {
        Write-Host "Déploiement dans $ns..."
        & $scriptPath -cluster $ns
    } else {
        Write-Warning "Script $scriptPath introuvable pour $ns"
    }
}

Write-Host "`nTous les déploiements sont terminés dans Minikube."
