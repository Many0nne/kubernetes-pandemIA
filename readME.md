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

## Lancer les clusters

Exécute le script d'initialisation :

- Windows (PowerShell) : `.\start-clusters.ps1`
- Unix/macOS (Bash) : `./start-clusters.sh`

Ce script :
- crée les clusters si nécessaires,
- démarre Minikube,
- déploie les fichiers Kubernetes associés.

## Contenu de chaque cluster pandemia-*

Chaque cluster représente un pays (`pandemia-fr`, `pandemia-us`, `pandemia-ch`) et contient :

### Volumes, ConfigMaps et Secrets

#### pandemia-init-script (ConfigMap)
Contient un script SQL d'initialisation pour MariaDB qui :
- crée les utilisateurs et la base de données `pandemia`,
- crée les tables : `continent`, `disease`, `country`, `region`, `global_data`.

#### pandemia-elt-env (Secret)
Contient les variables d’environnement nécessaires :
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
  - Port accessible : `30080`

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
- Port accessible : `30082`

## Vérifications

- Vérifie l’état des pods :
  ```bash
  kubectl get pods
  ```

- Pour accéder à l’interface web (frontend) :
  http://localhost:30080

- Pour accéder à l'API IA :
  http://localhost:30082

- Sinon il faut forward le port avec la commande : 
  kubectl port-forward service/pandemia-front-service 80:80
