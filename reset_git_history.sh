#!/bin/bash
# Script pour supprimer tout l'historique d'un dépôt Git

# Vérifier qu'on est bien dans un dépôt Git
if [ ! -d .git ]; then
    echo "Erreur: Vous n'êtes pas dans un dépôt Git"
    exit 1
fi

echo "⚠️ ATTENTION ⚠️"
echo "Cette opération va supprimer DÉFINITIVEMENT tout l'historique du dépôt Git."
echo "Toutes les branches, tags et commits seront perdus."
echo "Assurez-vous d'avoir fait une sauvegarde si nécessaire."
echo ""
read -p "Êtes-vous sûr de vouloir continuer? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "Opération annulée."
    exit 0
fi

# Récupérer le nom de la branche actuelle
current_branch=$(git branch --show-current)

# Sauvegarder l'état actuel des fichiers
echo "Sauvegarde de l'état actuel des fichiers..."
mkdir -p ../git_temp_backup
cp -r . ../git_temp_backup/
rm -rf ../git_temp_backup/.git

# Supprimer le dépôt Git et en créer un nouveau
echo "Suppression de l'historique Git..."
rm -rf .git
git init

# Ajouter tous les fichiers et faire un premier commit
echo "Ajout des fichiers au nouveau dépôt..."
git add .
git commit -m "Initial commit (historique précédent supprimé)"

echo "L'historique Git a été complètement supprimé."
echo "Les fichiers actuels ont été conservés dans un nouveau dépôt Git."
echo ""
echo "Si vous avez un dépôt distant, vous devrez forcer la mise à jour avec:"
echo "git remote add origin git@github.com:hhachim/infra.git"
echo "git push origin --force"
echo ""
echo "Une sauvegarde des fichiers a été créée dans: ../git_temp_backup/"