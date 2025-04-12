#!/bin/bash

# Script pour récupérer OVH_CONSUMER_KEY à partir de OVH_APPLICATION_KEY et OVH_APPLICATION_SECRET
# Utilisation: ./get_consumer_key.sh <OVH_APPLICATION_KEY> <OVH_APPLICATION_SECRET> [access_rules_file] [redirect_url]

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

# Vérification des arguments
if [ $# -lt 2 ]; then
  echo "Usage: $0 <OVH_APPLICATION_KEY> <OVH_APPLICATION_SECRET> [access_rules_file] [redirect_url]"
  exit 1
fi

OVH_APPLICATION_KEY="$1"
OVH_APPLICATION_SECRET="$2"

# Fichier des règles d'accès (optionnel)
ACCESS_RULES_FILE="$3"
REDIRECT_URL="$4"

# Si aucun fichier de règles n'est fourni, utiliser des règles par défaut
if [ -z "$ACCESS_RULES_FILE" ]; then
  ACCESS_RULES='[{"method":"GET","path":"/*"},{"method":"POST","path":"/*"},{"method":"PUT","path":"/*"},{"method":"DELETE","path":"/*"}]'
else
  if [ -f "$ACCESS_RULES_FILE" ]; then
    ACCESS_RULES=$(cat "$ACCESS_RULES_FILE")
  else
    echo "Le fichier de règles d'accès $ACCESS_RULES_FILE n'existe pas."
    exit 1
  fi
fi

# Construction de la requête pour OVH API
REQUEST_BODY="{\"accessRules\": $ACCESS_RULES"

# Ajouter l'URL de redirection si elle est spécifiée
if [ -n "$REDIRECT_URL" ]; then
  REQUEST_BODY="$REQUEST_BODY, \"redirection\": \"$REDIRECT_URL\""
fi

REQUEST_BODY="$REQUEST_BODY}"

# Effectuer la requête à l'API OVH
info "Envoi de la requête à l'API OVH..."

RESPONSE=$(curl -s -X POST "https://eu.api.ovh.com/1.0/auth/credential" \
  -H "Content-Type: application/json" \
  -H "X-Ovh-Application: $OVH_APPLICATION_KEY" \
  -d "$REQUEST_BODY")

# Vérifier si la requête a réussi
if echo "$RESPONSE" | grep -q "consumerKey"; then
  # Extraire la clé consommateur
  CONSUMER_KEY=$(echo "$RESPONSE" | grep -o '"consumerKey":"[^"]*"' | cut -d'"' -f4)
  VALIDATION_URL=$(echo "$RESPONSE" | grep -o '"validationUrl":"[^"]*"' | cut -d'"' -f4)
  
  success "Votre OVH_CONSUMER_KEY est: $CONSUMER_KEY"
  
  if [ -n "$VALIDATION_URL" ]; then
    info "Pour valider cette clé, veuillez visiter l'URL suivante:"
    echo -e "${GREEN}$VALIDATION_URL${NC}"
  fi
  
  # Créer le dossier secrets si nécessaire
  mkdir -p ./secrets
  
  # Vérifier si le fichier existe déjà
  if [ -f "./secrets/ovh_consumer_key.secret" ]; then
    warning "Le fichier ovh_consumer_key.secret existe déjà."
    read -p "Voulez-vous le remplacer? (y/n): " replace_file
    
    if [[ $replace_file == "y" || $replace_file == "Y" ]]; then
      echo "$CONSUMER_KEY" > ./secrets/ovh_consumer_key.secret
      success "La clé a été enregistrée dans ./secrets/ovh_consumer_key.secret"
    else
      info "Le fichier existant n'a pas été modifié."
    fi
  else
    echo "$CONSUMER_KEY" > ./secrets/ovh_consumer_key.secret
    success "La clé a été enregistrée dans ./secrets/ovh_consumer_key.secret"
  fi
  
  # Sauvegarder également les autres informations dans les fichiers secrets
  if [ ! -f "./secrets/ovh_endpoint.secret" ]; then
    echo "ovh-eu" > ./secrets/ovh_endpoint.secret
    success "Fichier ovh_endpoint.secret créé"
  fi
  
  if [ ! -f "./secrets/ovh_application_key.secret" ]; then
    echo "$OVH_APPLICATION_KEY" > ./secrets/ovh_application_key.secret
    success "Fichier ovh_application_key.secret créé"
  fi
  
  if [ ! -f "./secrets/ovh_application_secret.secret" ]; then
    echo "$OVH_APPLICATION_SECRET" > ./secrets/ovh_application_secret.secret
    success "Fichier ovh_application_secret.secret créé"
  fi
  
  echo ""
  info "Vous pouvez utiliser ces variables d'environnement:"
  echo "export OVH_APPLICATION_KEY=\"$OVH_APPLICATION_KEY\""
  echo "export OVH_APPLICATION_SECRET=\"$OVH_APPLICATION_SECRET\""
  echo "export OVH_CONSUMER_KEY=\"$CONSUMER_KEY\""
else
  error "Erreur lors de la requête à l'API OVH:"
  echo "$RESPONSE"
  exit 1
fi