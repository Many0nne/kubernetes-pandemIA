# Liste des clusters à gérer
CLUSTERS=("pandemia-fr" "pandemia-us" "pandemia-ch")

for CLUSTER in "${CLUSTERS[@]}"
do
  echo "Vérification du cluster: $CLUSTER"

  # Vérifie si le cluster existe déjà
  if ! minikube profile list | grep -q "$CLUSTER"; then
    echo "Création du cluster $CLUSTER..."
    minikube start -p "$CLUSTER" --memory=2048 --cpus=2
  else
    echo "Le cluster $CLUSTER existe déjà. Démarrage..."
    minikube start -p "$CLUSTER"
  fi
done

# Set contexte kubeconfig à la fin (optionnel)
echo "Configuration des contextes..."
for CLUSTER in "${CLUSTERS[@]}"
do
  kubectl config use-context "$CLUSTER" > /dev/null 2>&1 || echo "Le contexte $CLUSTER n'existe pas encore."
done

echo "Tous les clusters sont prêts."
