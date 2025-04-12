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

# Vérifier si le fichier .env existe, sinon le créer à partir du modèle
if [ ! -f ".env" ]; then
    info "Le fichier .env n'existe pas. Création à partir du modèle..."
    cp .env .env
    success "Fichier .env créé."
    
    # Demander à l'utilisateur les identifiants OVH
    read -p "Endpoint OVH (par défaut: ovh-eu): " ovh_endpoint
    ovh_endpoint=${ovh_endpoint:-ovh-eu}
    
    read -p "Clé d'application OVH: " ovh_app_key
    if [ -z "$ovh_app_key" ]; then
        warning "Vous devez fournir une clé d'application OVH."
        info "Créez-la sur https://eu.api.ovh.com/createApp/"
        exit 1
    fi
    
    read -p "Secret d'application OVH: " ovh_app_secret
    if [ -z "$ovh_app_secret" ]; then
        warning "Vous devez fournir un secret d'application OVH."
        info "Créez-le sur https://eu.api.ovh.com/createApp/"
        exit 1
    fi
    
    # Créer un script Python temporaire pour récupérer le Consumer Key
    mkdir -p temp
    cat > temp/get_consumer_key.py << EOF
import ovh
import sys

# Créez un client en utilisant vos identifiants d'application
client = ovh.Client(
    endpoint='$ovh_endpoint',
    application_key='$ovh_app_key',
    application_secret='$ovh_app_secret'
)

# Demandez des droits d'accès
ck = client.request_consumerkey(
    # Les droits pour gérer les enregistrements DNS
    access_rules=[
        {'method': 'GET', 'path': '/domain/*'},
        {'method': 'PUT', 'path': '/domain/*'},
        {'method': 'POST', 'path': '/domain/*'},
        {'method': 'DELETE', 'path': '/domain/*'}
    ]
)

print(ck['validationUrl'])
print(ck['consumerKey'])
EOF
    
    info "Récupération de la Consumer Key OVH..."
    info "Exécution du script Python via Docker..."
    
    # Exécuter le script Python via Docker pour obtenir la Consumer Key
    result=$(docker run --rm -v "$(pwd)/temp:/app" -w /app python:3.9-alpine sh -c "pip install ovh && python get_consumer_key.py")
    
    # Extraire l'URL de validation et la Consumer Key du résultat
    validation_url=$(echo "$result" | head -1)
    consumer_key=$(echo "$result" | tail -1)
    
    # Afficher l'URL de validation et la Consumer Key
    info "Veuillez visiter cette URL pour valider votre demande OVH:"
    echo -e "${GREEN}$validation_url${NC}"
    info "Votre Consumer Key OVH:"
    echo -e "${GREEN}$consumer_key${NC}"
    
    # Demander à l'utilisateur de confirmer la validation
    read -p "Avez-vous validé la demande sur le site OVH? (y/n): " validated
    if [[ $validated != "y" && $validated != "Y" ]]; then
        warning "Vous devez valider la demande sur le site OVH pour continuer."
        info "Conservez votre Consumer Key: $consumer_key"
        info "Vous pourrez la configurer manuellement plus tard dans le fichier .env"
        rm -rf temp
        exit 1
    fi
    
    # Nettoyer les fichiers temporaires
    rm -rf temp
    
    # Ajouter les variables OVH au fichier .env
    echo "" >> .env
    echo "# Configuration OVH pour DNS Challenge" >> .env
    echo "OVH_ENDPOINT=$ovh_endpoint" >> .env
    echo "OVH_APPLICATION_KEY=$ovh_app_key" >> .env
    echo "OVH_APPLICATION_SECRET=$ovh_app_secret" >> .env
    echo "OVH_CONSUMER_KEY=$consumer_key" >> .env
    
    success "Configuration OVH ajoutée au fichier .env."
else
    info "Le fichier .env existe déjà."
fi

# Créer le dossier data s'il n'existe pas
mkdir -p data

# Vérifier et gérer le fichier acme.json
if [ -f "data/acme.json" ]; then
    # Vérifier si le fichier est vide
    if [ -s "data/acme.json" ]; then
        info "Un fichier acme.json non vide existe déjà."
        read -p "Souhaitez-vous conserver le certificat existant? (y/n): " keep_cert
        
        if [[ $keep_cert == "y" || $keep_cert == "Y" ]]; then
            info "Conservation du certificat existant."
        else
            # Créer un backup avec la date et l'heure
            backup_file="data/acme.json.backup-$(date +%Y%m%d-%H%M%S)"
            info "Création d'une sauvegarde du fichier actuel vers $backup_file..."
            cp data/acme.json "$backup_file"
            success "Sauvegarde créée."
            
            # Créer un nouveau fichier acme.json
            info "Création d'un nouveau fichier acme.json..."
            touch data/acme.json
            chmod 600 data/acme.json
            success "Nouveau fichier acme.json créé avec les permissions 600."
        fi
    else
        # Le fichier existe mais il est vide
        info "Le fichier acme.json existe mais est vide."
        chmod 600 data/acme.json
        success "Permissions du fichier acme.json mises à jour (600)."
    fi
else
    # Le fichier n'existe pas, le créer
    info "Création du fichier acme.json..."
    touch data/acme.json
    chmod 600 data/acme.json
    success "Fichier acme.json créé avec les permissions 600."
fi

# Demander à l'utilisateur s'il souhaite démarrer Traefik maintenant
read -p "Souhaitez-vous démarrer Traefik avec la configuration DNS Challenge OVH maintenant? (y/n): " start_traefik
if [[ $start_traefik == "y" || $start_traefik == "Y" ]]; then
    # Démarrer Traefik avec la configuration OVH
    info "Démarrage de Traefik avec la configuration DNS Challenge OVH..."
    cp .env .env
    docker compose down
    docker compose up -d
    
    # Vérifier si Traefik a démarré avec succès
    if [ $? -eq 0 ]; then
        success "Traefik a été démarré avec succès en utilisant le DNS Challenge OVH!"
        domain=$(grep DOMAIN .env | cut -d '=' -f2)
        info "Pour accéder au tableau de bord, visitez: https://traefik.$domain"
        info "L'obtention du certificat wildcard peut prendre quelques minutes."
    else
        error "Une erreur s'est produite lors du démarrage de Traefik. Consultez les logs pour plus d'informations."
        info "Vous pouvez consulter les logs avec: docker compose logs"
    fi
else
    info "Vous pouvez démarrer Traefik plus tard avec la commande:"
    echo "cp .env.example .env && docker compose up -d"
fi