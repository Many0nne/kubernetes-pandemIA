$clusters = @("pandemia-us", "pandemia-fr", "pandemia-ch")
foreach ($cluster in $clusters) {
    # Démarre le cluster Minikube si besoin
    $profileExists = & minikube profile list | Select-String $cluster
    if (-not $profileExists) {
        Write-Host "Création et démarrage du cluster Minikube $cluster..."
        & minikube start -p $cluster --memory=2048 --cpus=2
    } else {
        $isRunning = & minikube status -p $cluster | Select-String "host: Running"
        if ($isRunning) {
            Write-Host "Le cluster Minikube $cluster est déjà démarré."
        } else {
            Write-Host "Démarrage du cluster Minikube $cluster..."
            & minikube start -p $cluster --memory=2048 --cpus=2
        }
    }

    # Crée le namespace s'il n'existe pas
    $nsExists = kubectl get namespace $cluster --ignore-not-found
    if (-not $nsExists) {
        Write-Host "Création du namespace $cluster..."
        kubectl create namespace $cluster
    } else {
        Write-Host "Namespace $cluster déjà existant."
    }

    # Crée le secret docker-registry si besoin
    $secretExists = kubectl get secret dockerhub-auth -n $cluster --ignore-not-found
    if (-not $secretExists) {
        Write-Host "Création du secret docker-registry DockerHub dans le namespace $cluster..."
        kubectl create secret docker-registry dockerhub-auth --docker-username=$dockerUser --docker-password=$dockerPwdPlain --docker-email=$dockerMail -n $cluster
    } else {
        Write-Host "Secret dockerhub-auth déjà existant dans $cluster."
    }

    # Exécution du script en passant le namespace en paramètre positionnel
    $scriptPath = Join-Path -Path ".\$cluster" -ChildPath "$cluster.ps1"
    if (Test-Path $scriptPath) {
        Write-Host "Exécution du script pour le namespace $cluster..."
        & $scriptPath -cluster $cluster
    } else {
        Write-Warning "Script $scriptPath introuvable."
    }
}

Write-Host "`nTous les namespaces (clusters simulés) sont prêts et déployés."
