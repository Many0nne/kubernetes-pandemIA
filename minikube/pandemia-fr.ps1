# pandemia-fr.ps1
param (
    [string]$cluster
)

Write-Host "`n=== Traitement du cluster: $cluster ==="

# Vérifie si le cluster existe déjà
$exists = & minikube profile list | Select-String $cluster
if (-not $exists) {
    Write-Host "Création du cluster $cluster..."
    & minikube start -p $cluster --memory=2048 --cpus=2
} else {
    $isRunning = & minikube status -p $cluster | Select-String "host: Running"
    if ($isRunning) {
        Write-Host "Le cluster $cluster est déjà démarré. Passage au déploiement..."
    } else {
        Write-Host "Démarrage du cluster $cluster..."
        & minikube start -p $cluster --memory=2048 --cpus=2
    }
}

# Change de contexte vers le cluster
Write-Host "Configuration du contexte pour $cluster..."
& kubectl config use-context $cluster

# Applique les fichiers dans un ordre défini
$folder = ".\$cluster"
if (Test-Path $folder) {
    # Ordre prioritaire
    $applyOrder = @("secret.yaml", "ConfigMap.yaml", "deployment.yaml")

    foreach ($filename in $applyOrder) {
        $fullPath = Join-Path $folder $filename
        if (Test-Path $fullPath) {
            Write-Host "Déploiement du fichier: $filename"
            & kubectl apply -f $fullPath
            Start-Sleep -Seconds 5
            & kubectl get pods
        } else {
            Write-Warning "Fichier $filename non trouvé dans $folder"
        }
    }

    # Appliquer les autres fichiers restants
    $otherFiles = Get-ChildItem -Path $folder -Filter *.yaml | Where-Object { $applyOrder -notcontains $_.Name }
    foreach ($file in $otherFiles) {
        Write-Host "Déploiement du fichier: $($file.Name)"
        & kubectl apply -f $file.FullName
        Start-Sleep -Seconds 5
    }

    # Affiche les pods à la fin du traitement du cluster
    Write-Host "`nÉtat des pods pour $cluster :"
    & kubectl get pods
} else {
    Write-Warning "Dossier $folder introuvable, pas de déploiement pour ce cluster."
}
