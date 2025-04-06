# Traefik Reverse Proxy avec OVH DNS - POC1

Ce POC (Proof of Concept) configure un reverse proxy Traefik avec gestion automatique des certificats SSL via Let's Encrypt, en utilisant la validation DNS d'OVH.

## Fonctionnalités

- Déploiement de Traefik v2 via Docker Compose
- Sécurisation automatique via Let's Encrypt avec challenge DNS OVH
- Dashboard Traefik sécurisé par authentification basic
- Configuration facilitée par variables d'environnement
- Service de test "whoami" pour valider la configuration
- Prise en charge des certificats wildcard pour les sous-domaines

## Prérequis

- Docker et Docker Compose installés
- Un domaine géré par OVH
- Credentials OVH (Application Key, Application Secret)

## Structure des fichiers

```
poc1/
├── .env                    # Variables d'environnement (non versionné)
├── .gitignore              # Fichiers ignorés par Git
├── docker-compose.yml      # Configuration des conteneurs Docker
├── get_consumer_key.sh     # Script pour obtenir la clé consommateur OVH
├── README.md               # Documentation (ce fichier)
├── secrets/                # Répertoire pour les secrets (non versionné)
│   ├── ovh_endpoint.secret
│   ├── ovh_application_key.secret
│   ├── ovh_application_secret.secret
│   └── ovh_consumer_key.secret
└── letsencrypt/            # Répertoire pour les certificats Let's Encrypt (non versionné)
    └── acme.json           # Fichier généré par Traefik contenant les certificats
```

## Guide d'installation

### 1. Préparation des credentials OVH

1. Créez une application sur [OVH API](https://api.ovh.com/createApp/) pour obtenir:
   - Application Key
   - Application Secret

2. Exécutez le script pour obtenir la Consumer Key:
   ```bash
   ./get_consumer_key.sh <APPLICATION_KEY> <APPLICATION_SECRET>
   ```

3. Suivez l'URL affichée pour autoriser l'application sur votre compte OVH.

### 2. Configuration de l'environnement

Créez un fichier `.env` avec les variables suivantes:

```env
# Configuration Traefik
TRAEFIK_VERSION=v2.10
TRAEFIK_SUBDOMAIN=traefik
TRAEFIK_NETWORK=traefik
TRAEFIK_NETWORK_EXTERNAL=false

# Configuration des ports
HTTP_PORT=80
HTTPS_PORT=443

# Configuration du dashboard
DASHBOARD_INSECURE=false
TRAEFIK_USERNAME=admin
# Généré avec: htpasswd -nb admin <votre_mot_de_passe>
TRAEFIK_PASSWORD_HASH=xxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Configuration Let's Encrypt
ACME_EMAIL=votre.email@domaine.com
DOMAIN=votre-domaine.fr
```

### 3. Démarrage des services

```bash
docker-compose up -d
```

### 4. Accès au dashboard

Une fois démarré, le dashboard Traefik est accessible à l'adresse:
```
https://traefik.votre-domaine.fr
```

Utilisez les identifiants définis dans le fichier `.env` pour vous connecter.

## Fonctionnement détaillé

### Résolution DNS avec OVH

Traefik utilise l'API OVH pour créer/modifier automatiquement les enregistrements DNS nécessaires à la validation des certificats Let's Encrypt. Cette approche permet:

1. D'obtenir des certificats wildcard (*.domain.com)
2. De fonctionner même sans exposition des ports 80/443 sur Internet

### Configuration des secrets

Les identifiants OVH sont stockés dans des fichiers secrets montés dans le conteneur Traefik. Cette méthode est plus sécurisée que l'utilisation directe de variables d'environnement.

### Certificats Let's Encrypt

Les certificats sont stockés dans le fichier `letsencrypt/acme.json` et sont automatiquement renouvelés avant expiration.

## Dépannage

### Problèmes courants

1. **Erreur d'autorisation OVH**
   - Vérifiez que vous avez bien validé l'URL d'autorisation après exécution du script `get_consumer_key.sh`
   - Assurez-vous que les permissions demandées sont suffisantes (GET, POST, PUT, DELETE)

2. **Échec de validation DNS**
   - Vérifiez que les identifiants OVH sont correctement configurés
   - Examinez les logs Traefik pour plus de détails: `docker-compose logs -f traefik`

3. **Certificats non générés**
   - Pour le débogage, décommentez la ligne du CA serveur de staging:
     ```
     - "--certificatesresolvers.myresolver.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
     ```
   - Activez les logs debug: `--log.level=DEBUG`

## Évolutions possibles

### Améliorations suggérées

1. **Sécurité renforcée**
   - Mise en place de middlewares Traefik pour:
     - Protection contre les DDoS
     - En-têtes de sécurité (HSTS, CSP)
     - Rate limiting

2. **Monitoring**
   - Intégration avec Prometheus pour la collecte de métriques
   - Tableau de bord Grafana pour la visualisation

3. **Haute disponibilité**
   - Configuration de plusieurs instances Traefik avec partage d'état
   - Utilisation d'un provider de configuration externe (Consul, etcd)

4. **Automatisation**
   - Script d'installation complet avec génération des fichiers de configuration
   - Intégration dans une pipeline CI/CD

5. **Autres providers DNS**
   - Support pour d'autres fournisseurs DNS (Cloudflare, AWS Route53, etc.)

### Intégration avec d'autres services

Ce POC peut facilement être étendu pour servir de passerelle à d'autres applications comme:
- Services web
- APIs
- Applications statiques
- WebSockets

## Maintenance

### Mise à jour de Traefik

Pour mettre à jour la version de Traefik, modifiez la variable `TRAEFIK_VERSION` dans le fichier `.env` et redémarrez les services:

```bash
docker-compose down
docker-compose up -d
```

### Sauvegarde

Pensez à sauvegarder régulièrement:
- Le dossier `letsencrypt/` contenant les certificats
- Le dossier `secrets/` contenant les identifiants OVH
- Le fichier `.env` contenant la configuration

## Notes importantes

- Le script `get_consumer_key.sh` doit être amélioré pour envoyer automatiquement les valeurs dans le dossier ./secrets (TODO)
- Les clés OVH sont des informations sensibles, ne les versionnez pas dans Git
- Utilisez le mode staging de Let's Encrypt lors des tests pour éviter les limitations de rate

## Références

- [Documentation Traefik](https://doc.traefik.io/)
- [Documentation Let's Encrypt](https://letsencrypt.org/docs/)
- [Documentation API OVH](https://api.ovh.com/)