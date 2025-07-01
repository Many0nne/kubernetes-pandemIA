# Documentation de déploiement Pandemia (Minikube)

## Prérequis

### 1. Installer Chocolatey (Windows)
Ouvre PowerShell en mode administrateur et exécute :

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = `
[System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 2. Installer Minikube
Toujours dans PowerShell :

```powershell
choco install minikube
```

### 3. Installer Docker Desktop
Télécharge Docker Desktop ici : https://www.docker.com/products/docker-desktop/

Assure-toi que Docker Desktop est lancé avant de continuer.

## Fonctionnement technique & orchestration


L'orchestration du déploiement repose sur des scripts PowerShell (`.ps1`) pour Windows et Bash (`.sh`) pour Unix/macOS, situés dans le dossier `minikube/`. Ces scripts automatisent la création des namespaces et le déploiement des ressources pour chaque pays (France, US, Suisse) dans un unique cluster Minikube.

- **start-clusters.ps1 / .sh** :
  - Parcourt la liste des namespaces (`pandemia-fr`, `pandemia-us`, `pandemia-ch`).
  - Crée les namespaces s'ils n'existent pas (plus de gestion de secrets DockerHub, les images sont publiques).
  - Utilise `kubectl` pour changer de contexte et déployer les ressources sur le namespace cible.

- **Orchestration Kubernetes** :
  - Chaque namespace Minikube est isolé et possède ses propres ressources (base de données, frontend, API, etc.).
  - Les jobs ELT sont lancés automatiquement à chaque déploiement.

- **Suppression** :
  - Le script `nuke-clusters.ps1` permet de supprimer tous les namespaces et de nettoyer les images Docker locales utilisées par Minikube.

## Lancer les clusters

Exécute le script d'initialisation :

- Windows (PowerShell) : `./start-clusters.ps1`
- Unix/macOS (Bash) : `./start-clusters.sh`

Ce script :
- démarre Minikube si besoin,
- crée les namespaces nécessaires,
- déploie les fichiers Kubernetes associés dans chaque namespace (France, US, Suisse).

## Power BI / Rapport

### Problématique d'affichage du PBIX

Le rapport Power BI est packagé sous forme de fichier `.pbix` et servi par un conteneur Nginx dans le cluster. Cependant, il n'est pas possible d'afficher ce fichier directement dans le navigateur car :
- Power BI Desktop nécessite une interface graphique Windows pour ouvrir un `.pbix`.
- Les clusters Minikube/Kubernetes n'ont pas d'environnement graphique.
- En accédant à l'URL du service Nginx, le fichier `.pbix` est téléchargé, mais ne peut pas être visualisé directement dans le navigateur.

### Solution apportée

Pour permettre la consultation du rapport sans installation locale de Power BI Desktop, une version PDF du rapport a été générée et est disponible dans le dépôt. Vous pouvez donc consulter le rapport au format PDF, accessible depuis la page d'accueil du frontend ou directement dans le dossier du projet.

## Contenu de chaque cluster pandemia-*

Chaque cluster représente un pays (`pandemia-fr`, `pandemia-us`, `pandemia-ch`) et contient :

### Volumes, ConfigMaps et Secrets

#### pandemia-init-script (ConfigMap)
Contient un script SQL d'initialisation pour MariaDB qui :
- crée les utilisateurs et la base de données `pandemia`,
- crée les tables : `continent`, `disease`, `country`, `region`, `global_data`.


#### pandemia-elt-env (Secret)
Contient les variables d’environnement nécessaires (aucun secret DockerHub n'est requis, les images sont publiques) :
```yaml
DB_HOST: pandemia-bdd-service
DB_USER: pandemia
DB_PASSWORD: root
DB_NAME: pandemia
API_KEY: ihYY5!PWWK96JzUw@E^wBKAbMT49s*eX&Pnvq*5
API_KEY_NAME: access_token
MYSQL_ROOT_PASSWORD: root
MYSQL_DATABASE: pandemia
MYSQL_USER: pandemia
MYSQL_PASSWORD: root
```

## Déploiements Kubernetes

### MariaDB

- Nom : `pandemia-bdd`
- Image : `mariadb:10.11`
- Volume : PVC `pandemia-bdd-pvc` (1Gi)
- Init script : monté depuis `pandemia-init-script`

Service associé : `pandemia-bdd-service` (port 3306)


### Frontend React

- Nom : `pandemia-front`
- Image : `terrybarillon/pandemia-front:latest`
- Service : `pandemia-front-service`
  - Type : `NodePort`
  - Port accessible : `3000` (par défaut, voir le port exposé dans le service)

### ELT (Job)

- Nom : `pandemia-elt-job`
- Image : `terrybarillon/elt-mspr:latest`
- Type : `Job`
- Politique de redémarrage : `Never`
- Retry : 2 fois max (`backoffLimit: 2`)


### API IA

- Nom : `pandemia-api-ia`
- Image : `terrybarillon/pandemia-api-ia:latest`
- Ressources :
  - requests : 512Mi RAM / 0.5 CPU
  - limits : 1Gi RAM / 1 CPU

Service associé : `pandemia-api-ia-service`
- Type : `NodePort`
- Port accessible : `8081` (par défaut, voir le port exposé dans le service)

## Vérifications

- Vérifie l’état des pods :
  ```bash
  kubectl get pods
  ```

- Pour accéder à l’interface web (frontend) :

  http://localhost:3000

- Pour accéder à l'API IA :
  http://localhost:8081

- Sinon il faut forward le port avec la commande :
  kubectl port-forward service/pandemia-front-service 3000:3000

## Schéma d'architecture

```
+-----------------------------+
|        Minikube Cluster     |
|  (1 seul cluster, 3 NS)     |
+-----------------------------+
   |         |         |
   |         |         |
   v         v         v
+--------+ +--------+ +--------+
|pandemia| |pandemia| |pandemia|
|  -us   | |  -fr   | |  -ch   |
+--------+ +--------+ +--------+
   |           |         |
   |           |         |
   v           v         v
+-----------------------------+
|   Ressources par namespace   |
|  - pandemia-bdd (MariaDB)    |
|  - pandemia-front (React)    |
|  - pandemia-api-ia (API IA)  |
|  - pandemia-elt-job (ELT)    |
|  - pptx-nginx (Nginx)        |
|  - Services NodePort         |
|  - Secrets & ConfigMaps      |
+-----------------------------+
```

Chaque namespace (`pandemia-us`, `pandemia-fr`, `pandemia-ch`) isole ses propres ressources applicatives, base de données, jobs et services. Tout est déployé dans un unique cluster Minikube local.
