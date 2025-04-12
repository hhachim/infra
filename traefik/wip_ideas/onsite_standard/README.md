# Configuration Traefik 2.x avec Docker

Ce projet fournit une configuration Docker Compose pour Traefik 2.x, facilitant la gestion des certificats SSL, le routage des services et la sécurisation de vos applications.

## Fonctionnalités

- 🔐 Configuration HTTPS automatique avec Let's Encrypt
- 🔒 Redirection automatique HTTP vers HTTPS
- 📊 Tableau de bord Traefik sécurisé par authentification
- 🛡️ En-têtes de sécurité configurés
- 🔄 Environnement facilement configurable via variables d'environnement
- 🚀 Simple à déployer grâce au script d'installation

## Prérequis

- Docker
- Docker Compose
- Un nom de domaine pointant vers votre serveur

## Installation rapide

```bash
# Cloner le dépôt
git clone https://github.com/votre-compte/traefik-docker.git
cd traefik-docker

# Exécuter le script d'installation (il vous guidera pour la configuration)
chmod +x setup.sh
./setup.sh
```

## Installation manuelle

1. Créer un fichier `.env` à partir du modèle
   ```bash
   cp .env.example .env
   ```

2. Modifier le fichier `.env` avec vos paramètres
   ```bash
   nano .env
   ```

3. Créer le fichier acme.json avec les bonnes permissions
   ```bash
   mkdir -p data
   touch data/acme.json
   chmod 600 data/acme.json
   ```

4. Démarrer Traefik
   ```bash
   docker-compose up -d
   ```

## Configuration

### Variables d'environnement

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `DOMAIN` | Domaine principal | pocs.hachim.fr |
| `TRAEFIK_SUBDOMAIN` | Sous-domaine pour accéder au tableau de bord | traefik |
| `TRAEFIK_USERNAME` | Nom d'utilisateur pour le tableau de bord | admin |
| `TRAEFIK_PASSWORD_HASH` | Hash du mot de passe (généré avec htpasswd) | admin |
| `ACME_EMAIL` | Email pour Let's Encrypt | contact@example.com |
| `HTTP_PORT` | Port HTTP | 80 |
| `HTTPS_PORT` | Port HTTPS | 443 |
| `DASHBOARD_INSECURE` | Active/désactive l'accès non sécurisé au tableau de bord | false |
| `TRAEFIK_VERSION` | Version de l'image Traefik à utiliser | v2.10 |

### Générer un hash de mot de passe

Pour générer un nouveau hash de mot de passe pour le tableau de bord :

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin MonNouveauMotDePasse
```

Copiez la sortie dans le fichier `.env` pour la variable `TRAEFIK_PASSWORD_HASH`.

## Structure des dossiers

```
.
├── .env                  # Variables d'environnement (à partir de .env.example)
├── .env.example          # Exemple de variables d'environnement
├── docker-compose.yml    # Configuration Docker Compose
├── data/                 # Dossier contenant les configurations
│   ├── acme.json         # Certificats Let's Encrypt (généré automatiquement)
│   ├── config.yml        # Configuration dynamique de Traefik
│   └── traefik.yml       # Configuration statique de Traefik
├── templates/            # Modèles de configuration
│   ├── config.yml        # Modèle pour config.yml
│   └── traefik.yml       # Modèle pour traefik.yml
└── setup.sh              # Script d'installation

```

## Accès au tableau de bord

Une fois Traefik démarré, vous pouvez accéder au tableau de bord à l'adresse suivante :

```
https://TRAEFIK_SUBDOMAIN.DOMAIN
```

Par exemple : https://traefik.pocs.hachim.fr

Utilisez les identifiants configurés dans le fichier `.env`.

## Sécurité

Cette configuration inclut plusieurs améliorations de sécurité :

- Redirection automatique HTTP vers HTTPS
- En-têtes de sécurité (HSTS, XSS Protection, etc.)
- Tableau de bord protégé par authentification
- TLS 1.2+ avec suites de chiffrement modernes
- Limitation de débit basique pour la protection contre les DDoS

## Utilisation avec d'autres services

Pour configurer d'autres services avec Traefik, ajoutez des labels à vos services dans le fichier docker-compose.yml :

```yaml
services:
  monservice:
    image: monimage
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.monservice.rule=Host(`monservice.${DOMAIN}`)"
      - "traefik.http.routers.monservice.tls=true"
      - "traefik.http.routers.monservice.tls.certresolver=myresolver"
      - "traefik.http.services.monservice.loadbalancer.server.port=8080"
    networks:
      - traefik

networks:
  traefik:
    external: true
```

## Maintenance

### Mise à jour de Traefik

Pour mettre à jour Traefik vers une nouvelle version, modifiez la variable `TRAEFIK_VERSION` dans le fichier `.env` et redémarrez les services :

```bash
docker-compose down
docker-compose up -d
```

### Renouvellement des certificats

Les certificats Let's Encrypt sont automatiquement renouvelés par Traefik.

## Dépannage

### Vérifier les logs

```bash
docker-compose logs traefik
```

### Problèmes courants

#### Certificat non émis

Vérifiez que :
- Votre domaine pointe correctement vers votre serveur
- Les ports 80 et 443 sont accessibles depuis l'extérieur
- Le fichier acme.json a les bonnes permissions (600)

#### Tableau de bord inaccessible

Vérifiez que :
- Le service Traefik est en cours d'exécution (`docker-compose ps`)
- Les identifiants sont corrects dans le fichier .env
- Le sous-domaine est correctement configuré dans votre DNS

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## Licence

MIT