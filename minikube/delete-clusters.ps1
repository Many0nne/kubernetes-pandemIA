$clusters = @("pandemia-fr", "pandemia-us", "pandemia-ch")

foreach ($cluster in $clusters) {
    Write-Host "`n=== Suppression du cluster: $cluster ==="

    # Vérifie si le cluster existe
    $exists = & minikube profile list | Select-String $cluster
    if ($exists) {
        Write-Host "Suppression en cours du cluster $cluster..."
        & minikube delete -p $cluster
    } else {
        Write-Host "Cluster $cluster non trouvé, rien à supprimer."
    }
}

Write-Host "`n🗑️ Tous les clusters spécifiés ont été traités pour suppression."
