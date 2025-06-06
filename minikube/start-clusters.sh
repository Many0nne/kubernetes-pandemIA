# Liste des clusters
clusters=("pandemia-us" "pandemia-fr" "pandemia-ch")

# Boucle sur chaque cluster
for cluster in "${clusters[@]}"; do
    script="./${cluster}.sh"
    if [ -f "$script" ]; then
        echo "Exécution du script pour le cluster $cluster..."
        bash "$script" "$cluster"
    else
        echo "Script $script introuvable."
    fi
done

echo -e "\n Tous les clusters sont prêts et déployés."
