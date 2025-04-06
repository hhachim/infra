# Portainer - Interface de gestion Docker

Ce service déploie Portainer, une interface utilisateur web intuitive pour gérer les conteneurs Docker, les images, les réseaux et les volumes.

## Fonctionnalités

- Interface web complète pour la gestion de Docker
- Gestion des conteneurs, images, volumes et réseaux
- Déploiement et mise à jour d'applications via stacks
- Gestion des secrets Docker
- Visualisation des logs et des métriques
- Support multi-utilisateurs avec RBAC (Role-Based Access Control)
- Support pour Docker Swarm
- Sécurisé avec Traefik et HTTPS

## Prérequis

- Docker et Docker Compose installés
- Traefik configuré comme reverse proxy (voir pocs/traefik/poc1)
- Réseau Docker "traefik" créé et configuré

## Structure des fichiers

```
services/portainer/
├── docker-compose.yml     # Configuration du service Portainer
├── .env                   # Variables d'environnement (non versionné)
└── README.md              # Documentation (ce fichier)
```

## Configuration

### Fichier .env

Créez un fichier `.env` avec les variables suivantes:

```env
# Configuration Portainer
PORTAINER_VERSION=latest
PORTAINER_SUBDOMAIN=portainer
DOMAIN=votre-domaine.fr

# Configuration du volume
PORTAINER_DATA_PATH=./data

# Configuration du réseau
TRAEFIK_NETWORK=traefik
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:${PORTAINER_VERSION}
    container_name: portainer
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${PORTAINER_DATA_PATH}:/data
    networks:
      - traefik
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(`${PORTAINER_SUBDOMAIN}.${DOMAIN}`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.tls.certresolver=myresolver"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"
      # Configuration des en-têtes de sécurité
      - "traefik.http.routers.portainer.middlewares=portainer-secure-headers"
      - "traefik.http.middlewares.portainer-secure-headers.headers.sslRedirect=true"
      - "traefik.http.middlewares.portainer-secure-headers.headers.stsSeconds=31536000"
      - "traefik.http.middlewares.portainer-secure-headers.headers.contentSecurityPolicy=default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; connect-src 'self' ws: wss:;"

networks:
  traefik:
    external: true
    name: ${TRAEFIK_NETWORK}
```

## Déploiement

### 1. Créer le répertoire de données

```bash
mkdir -p ./data
```

### 2. Démarrer Portainer

```bash
docker-compose up -d
```

### 3. Premier accès

Une fois démarré, accédez à Portainer via:
```
https://portainer.votre-domaine.fr
```

Lors de la première connexion, vous devrez:
1. Créer un compte administrateur
2. Configurer l'environnement Docker local

## Utilisation

### Gestion des conteneurs

- **Liste des conteneurs**: Visualisez, démarrez, arrêtez et redémarrez tous vos conteneurs
- **Création de conteneur**: Lancez de nouveaux conteneurs à partir d'images existantes
- **Logs**: Consultez les logs de vos conteneurs en temps réel
- **Stats**: Surveillez l'utilisation des ressources (CPU, mémoire, réseau)

### Gestion des stacks

- **Déploiement**: Créez des stacks à partir de fichiers docker-compose.yml
- **Mise à jour**: Modifiez et redéployez facilement vos stacks
- **État**: Surveillez l'état de tous les services dans chaque stack

### Configuration avancée

- **Réseaux**: Créez et gérez des réseaux Docker personnalisés
- **Volumes**: Gérez les volumes persistants pour vos données
- **Images**: Téléchargez, créez et supprimez des images Docker
- **Registres**: Connectez-vous à des registres Docker privés

## Sécurité

### Bonnes pratiques

1. **Sécurisation de l'accès**
   - Utilisez des mots de passe forts
   - Activez l'authentification à deux facteurs
   - Configurez des rôles utilisateurs avec permissions limitées

2. **Protection de l'API Docker**
   - Le socket Docker est monté en lecture seule (`/var/run/docker.sock:ro`)
   - Utilisez le contrôle d'accès basé sur les rôles (RBAC)

3. **Isolation réseau**
   - Utilisez Traefik comme point d'entrée unique
   - Configurez correctement les en-têtes de sécurité

## Sauvegardes

### Données à sauvegarder

1. **Volume de données Portainer**
   - Contient les configurations utilisateur, équipes, environnements
   - Sauvegardez régulièrement le répertoire `./data`

2. **Fichiers de configuration**
   - docker-compose.yml
   - .env

### Procédure de sauvegarde

```bash
# Arrêter temporairement Portainer
docker-compose stop

# Sauvegarder les données
tar czf portainer-backup-$(date +%Y%m%d).tar.gz ./data

# Redémarrer Portainer
docker-compose start
```

## Dépannage

### Problèmes courants

1. **Erreur d'accès au socket Docker**
   - Vérifiez les permissions du fichier `/var/run/docker.sock`
   - Assurez-vous que l'utilisateur Docker a accès au socket

2. **Problèmes de connexion**
   - Vérifiez la configuration Traefik
   - Assurez-vous que le port 9000 est exposé correctement

3. **Perte d'accès administrateur**
   - Utilisez la commande de réinitialisation du mot de passe:
     ```bash
     docker run --rm -v portainer_data:/data portainer/helper-reset-password
     ```

## Évolutions possibles

### Améliorations suggérées

1. **Haute disponibilité**
   - Déploiement de Portainer en mode cluster
   - Configuration avec des agents pour la gestion multi-nœuds

2. **Intégration CI/CD**
   - Webhooks pour le déploiement automatisé
   - Intégration avec GitLab, GitHub ou Bitbucket

3. **Monitoring avancé**
   - Intégration avec Prometheus et Grafana
   - Configuration des alertes

4. **Gestion des secrets**
   - Utilisation de solutions externes comme HashiCorp Vault
   - Intégration avec les secrets Docker Swarm

5. **Authentication externe**
   - Configuration LDAP/Active Directory
   - SSO avec OAuth ou SAML

### Extensions

- **Portainer Business Edition**
  - Fonctionnalités supplémentaires pour les entreprises
  - Support pour Kubernetes
  - Gestion de la conformité

## Maintenance

### Mise à jour de Portainer

Pour mettre à jour Portainer vers la dernière version:

```bash
# Modifier la version dans .env (ou garder 'latest')
docker-compose pull
docker-compose down
docker-compose up -d
```

### Nettoyage

Utilisez Portainer pour nettoyer régulièrement:
- Images inutilisées
- Conteneurs arrêtés
- Volumes orphelins
- Build cache

## Références

- [Documentation officielle Portainer](https://docs.portainer.io/)
- [GitHub Portainer](https://github.com/portainer/portainer)
- [Docker Hub Portainer](https://hub.docker.com/r/portainer/portainer-ce)