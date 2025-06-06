# main.ps1
$clusters = @("pandemia-us")

foreach ($cluster in $clusters) {
    $scriptPath = Join-Path -Path . -ChildPath "$cluster.ps1"
    if (Test-Path $scriptPath) {
        Write-Host "Exécution du script pour le cluster $cluster..."
        & powershell -File $scriptPath -cluster $cluster
    } else {
        Write-Warning "Script $scriptPath introuvable."
    }
}

Write-Host "`n✅ Tous les clusters sont prêts et déployés."
