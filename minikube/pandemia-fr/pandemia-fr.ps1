param(
    [string]$cluster
)

Write-Host "Déploiement dans le namespace $cluster..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

kubectl apply -n $cluster -f "$scriptDir/secret.yaml"
kubectl apply -n $cluster -f "$scriptDir/configmap.yaml"

Get-ChildItem -Path $scriptDir -Filter *.yaml | Where-Object { $_.Name -notmatch 'secret.yaml|configmap.yaml' } | ForEach-Object {
    Write-Host "Application de $($_.Name) dans le namespace $cluster"
    kubectl apply -n $cluster -f $_.FullName
}

Write-Host "Déploiement terminé dans le namespace $cluster."
