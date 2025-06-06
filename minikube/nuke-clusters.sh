clusters=("pandemia-fr" "pandemia-us" "pandemia-ch")

for cluster in "${clusters[@]}"; do
    echo -e "\n=== Suppression du cluster: $cluster ==="

    # Vérifie si le cluster existe
    if minikube profile list | grep -q "$cluster"; then
        echo "Suppression en cours du cluster $cluster..."
        minikube delete -p "$cluster"
    else
        echo "Cluster $cluster non trouvé, rien à supprimer."
    fi
done

# Supprimer les images Docker locales utilisées par Minikube
echo -e "\n=== Nettoyage des images Docker inutiles ==="
images=$(docker images --filter=reference='gcr.io/k8s-minikube/kic*' --format "{{.Repository}}:{{.Tag}}")

for img in $images; do
    echo "Suppression de l'image: $img"
    docker rmi "$img"
done

echo -e "\n Tous les clusters spécifiés ont été traités pour suppression."
