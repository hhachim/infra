#!/bin/bash

# Chemin vers le fichier docker-compose.yml
COMPOSE_FILE="docker-compose.yml"
# Détecte si "docker compose" est disponible
if command -v docker > /dev/null && docker compose version > /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose > /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    echo "Erreur : ni 'docker compose' ni 'docker-compose' n'est disponible."
    exit 1
fi
# Vérifie si le fichier docker-compose.yml existe
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Erreur : $COMPOSE_FILE n'existe pas dans le répertoire actuel."
    exit 1
fi

# Lancer Docker Compose
echo "Lancement de Docker Compose..."
$DOCKER_COMPOSE_CMD up -d

# Vérifie si le lancement a réussi
if [ $? -eq 0 ]; then
    echo "Docker Compose a été lancé avec succès."
else
    echo "Erreur lors du lancement de Docker Compose."
    exit 1
fi