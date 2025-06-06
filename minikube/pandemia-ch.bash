cluster="$1"

if [ -z "$cluster" ]; then
    echo "Usage: $0 <nom_du_cluster>"
    exit 1
fi

echo -e "\n=== Traitement du cluster: $cluster ==="

# Vérifie si le cluster existe déjà
if ! minikube profile list | grep -q "$cluster"; then
    echo "Création du cluster $cluster..."
    minikube start -p "$cluster" --memory=2048 --cpus=2
else
    if minikube status -p "$cluster" | grep -q "host: Running"; then
        echo "Le cluster $cluster est déjà démarré. Passage au déploiement..."
    else
        echo "Démarrage du cluster $cluster..."
        minikube start -p "$cluster" --memory=2048 --cpus=2
    fi
fi

# Change de contexte vers le cluster
echo "Configuration du contexte pour $cluster..."
kubectl config use-context "$cluster"

# Applique les fichiers dans un ordre défini
folder="./$cluster"
if [ -d "$folder" ]; then
    # Ordre prioritaire
    apply_order=("secret.yaml" "ConfigMap.yaml" "deployment.yaml")

    for filename in "${apply_order[@]}"; do
        full_path="$folder/$filename"
        if [ -f "$full_path" ]; then
            echo "Déploiement du fichier: $filename"
            kubectl apply -f "$full_path"
            sleep 5
            kubectl get pods
        else
            echo "Fichier $filename non trouvé dans $folder"
        fi
    done

    # Appliquer les autres fichiers restants
    for file in "$folder"/*.yaml; do
        base_name=$(basename "$file")
        if [[ ! " ${apply_order[*]} " =~ " $base_name " ]]; then
            echo "Déploiement du fichier: $base_name"
            kubectl apply -f "$file"
            sleep 5
        fi
    done

    echo -e "\nÉtat des pods pour $cluster :"
    kubectl get pods
else
    echo "Dossier $folder introuvable, pas de déploiement pour ce cluster."
fi
