#!/bin/bash

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher un message d'information
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Fonction pour afficher un message de succès
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Fonction pour afficher un message d'erreur
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour afficher un message d'avertissement
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    error "Docker n'est pas installé. Veuillez installer Docker avant de continuer."
    exit 1
fi

# Vérifier si Docker Compose est disponible (soit en commande séparée, soit en plugin)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
    info "Docker Compose (commande séparée) détecté."
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
    info "Docker Compose (plugin Docker) détecté."
else
    error "Docker Compose n'est pas disponible. Veuillez installer Docker Compose (commande séparée ou plugin Docker) avant de continuer."
    exit 1
fi

# Créer les répertoires nécessaires
info "Création des répertoires..."
mkdir -p data
success "Répertoires créés."

# Copier les fichiers de configuration s'ils n'existent pas
if [ ! -f "data/traefik.yml" ]; then
    info "Copie du fichier traefik.yml..."
    cp templates/traefik.yml data/traefik.yml
    success "Fichier traefik.yml copié."
    
    # Charger les variables d'environnement si le fichier .env existe
    if [ -f ".env" ]; then
        # Charger les variables du fichier .env
        source .env
        
        # Remplacer la valeur de dashboard insecure
        if [ "$DASHBOARD_INSECURE" = "true" ]; then
            info "Configuration du dashboard en mode non sécurisé..."
            sed -i 's/insecure: false/insecure: true/g' data/traefik.yml
            warning "⚠️ Attention: Le tableau de bord est configuré en mode non sécurisé!"
        fi
    fi
fi

if [ ! -f "data/config.yml" ]; then
    info "Copie du fichier config.yml..."
    cp templates/config.yml data/config.yml
    success "Fichier config.yml copié."
    
    # Remplacer les variables dans le fichier config.yml
    if [ -f ".env" ]; then
        # Charger les variables du fichier .env
        source .env
        
        # Remplacer le domaine et le sous-domaine
        info "Configuration du domaine et sous-domaine dans config.yml..."
        sed -i "s/Host(\`traefik.pocs.hachim.fr\`)/Host(\`$TRAEFIK_SUBDOMAIN.$DOMAIN\`)/g" data/config.yml
        
        # Remplacer les identifiants
        if [ -n "$TRAEFIK_USERNAME" ] && [ -n "$TRAEFIK_PASSWORD_HASH" ]; then
            info "Configuration des identifiants d'accès au tableau de bord..."
            sed -i "s/- \"admin:.*/- \"$TRAEFIK_USERNAME:$TRAEFIK_PASSWORD_HASH\"/g" data/config.yml
        fi
    fi
fi

# Créer le fichier acme.json avec les bonnes permissions si nécessaire
if [ ! -f "data/acme.json" ]; then
    info "Création du fichier acme.json..."
    touch data/acme.json
    chmod 600 data/acme.json
    success "Fichier acme.json créé avec les permissions 600."
fi

# Vérifier si le fichier .env existe, sinon le créer à partir du modèle
if [ ! -f ".env" ]; then
    info "Création du fichier .env à partir du modèle..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        success "Fichier .env créé à partir du modèle."
        
        # Demander à l'utilisateur s'il souhaite configurer le fichier .env
        read -p "Souhaitez-vous configurer le fichier .env maintenant? (y/n): " configure_env
        if [[ $configure_env == "y" || $configure_env == "Y" ]]; then
            # Demander les valeurs pour le fichier .env
            read -p "Nom de domaine (ex: exemple.com): " domain
            read -p "Sous-domaine pour Traefik (ex: traefik): " traefik_subdomain
            read -p "Email pour Let's Encrypt: " acme_email
            read -p "Nom d'utilisateur pour le tableau de bord (défaut: admin): " traefik_username
            traefik_username=${traefik_username:-admin}
            
            # Générer un mot de passe aléatoire ou utiliser celui fourni par l'utilisateur
            read -p "Souhaitez-vous générer un mot de passe aléatoire? (y/n): " generate_password
            if [[ $generate_password == "y" || $generate_password == "Y" ]]; then
                password=$(openssl rand -base64 12)
                info "Mot de passe généré: $password"
            else
                read -s -p "Mot de passe pour le tableau de bord: " password
                echo
            fi
            
            # Générer le hash du mot de passe
            password_hash=$(docker run --rm httpd:2.4-alpine htpasswd -nbB $traefik_username $password | cut -d ":" -f 2)
            
            # Mettre à jour le fichier .env
            sed -i "s/DOMAIN=.*/DOMAIN=$domain/g" .env
            sed -i "s/TRAEFIK_SUBDOMAIN=.*/TRAEFIK_SUBDOMAIN=$traefik_subdomain/g" .env
            sed -i "s/ACME_EMAIL=.*/ACME_EMAIL=$acme_email/g" .env
            sed -i "s/TRAEFIK_USERNAME=.*/TRAEFIK_USERNAME=$traefik_username/g" .env
            sed -i "s|TRAEFIK_PASSWORD_HASH=.*|TRAEFIK_PASSWORD_HASH=$password_hash|g" .env
            
            success "Fichier .env configuré avec succès."
            info "URL du tableau de bord: https://$traefik_subdomain.$domain"
            info "Identifiants: $traefik_username / $password"
        fi
    else
        error "Le fichier .env.example n'existe pas. Impossible de créer le fichier .env."
        exit 1
    fi
fi

# Créer un fichier .env.example si nécessaire
if [ ! -f ".env.example" ]; then
    info "Création du fichier .env.example..."
    cat > .env.example << EOL
# Configuration du domaine
DOMAIN=pocs.hachim.fr
TRAEFIK_SUBDOMAIN=traefik

# Informations d'authentification (défaut)
TRAEFIK_USERNAME=admin
TRAEFIK_PASSWORD_HASH=\$2y\$05\$vI8esHzt7jGcOkJz7ZRvduaLahTf1p8jtnDjC0az0Aw7LPyahUIZC

# Configuration Let's Encrypt
ACME_EMAIL=contact@example.com

# Ports exposés (modification possible si 80/443 sont utilisés)
HTTP_PORT=80
HTTPS_PORT=443

# Configuration de sécurité
DASHBOARD_INSECURE=false

# Version de Traefik
TRAEFIK_VERSION=v2.10
EOL
    success "Fichier .env.example créé."
fi

# Créer les dossiers templates si nécessaire
if [ ! -d "templates" ]; then
    info "Création du dossier templates..."
    mkdir -p templates
    success "Dossier templates créé."
    
    # Copier les modèles de configuration dans templates
    info "Création des modèles de configuration..."
    cp data/traefik.yml templates/traefik.yml
    cp data/config.yml templates/config.yml
    success "Modèles de configuration créés."
fi

# Tout est prêt, démarrer Traefik
info "Configuration terminée. Démarrage de Traefik..."
$DOCKER_COMPOSE up -d

# Vérifier si Traefik a démarré avec succès
if [ $? -eq 0 ]; then
    success "Traefik a été démarré avec succès!"
    info "Pour accéder au tableau de bord, visitez: https://$(grep TRAEFIK_SUBDOMAIN .env | cut -d '=' -f2).$(grep DOMAIN .env | cut -d '=' -f2)"
    info "Utilisez les identifiants configurés dans le fichier .env"
else
    error "Une erreur s'est produite lors du démarrage de Traefik. Consultez les logs pour plus d'informations."
    info "Vous pouvez consulter les logs avec: $DOCKER_COMPOSE logs"
fi