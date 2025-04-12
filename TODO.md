# TODO : Environnement Docker pour Symfony

## Inspiration
- S'inspirer de [Laradock](https://laradock.io/), un environnement complet de développement PHP.
- Examiner les configurations Docker adaptées aux projets Symfony.

## Tâches
1. Rechercher des configurations Docker pour Symfony.
2. Identifier les services essentiels :
    - PHP-FPM
    - NGINX
    - MySQL/PostgreSQL
    - Redis
    - Elasticsearch (si nécessaire)
3. Créer un fichier Docker Compose :
    - Définir les services et les réseaux.
    - Utiliser un fichier `.env` pour la configuration.
4. Tester la configuration avec un projet Symfony d'exemple.
5. Documenter le processus de configuration et les instructions d'utilisation.

## Notes
- Assurer la compatibilité avec les versions de Symfony.
- Optimiser pour le développement local et les pipelines CI/CD.
- Envisager l'ajout de Xdebug pour le débogage.

