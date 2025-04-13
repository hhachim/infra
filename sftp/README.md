# Introduction

Ce projet a pour but d'avoir rapidement un serveur sftp prêt à l'emoploi où on peut s'y connecter soit avec un login/mot de passe ou avec un login/clé ssh.

Les problématiques de logs, monitoring, quota d'espace disque nne sont pas traitées.

Techniquement, la phylosophie de ce projet est de ne pas re-inventer la roue en réutilisant une stack technique robuste, connu/populaire, maintenu, documentée etc.
Le choix s'est porté rapidement sur docker avec l'image https://hub.docker.com/r/atmoz/sftp, qui moment de la création de ce projet (2024-04-17) comptabilisait déjà plus d'un milliard de téléchargement.

Au final, ce projet est une proposition de l'usage de l'image https://hub.docker.com/r/atmoz/sftp pour répondre un use case bien précis :  celui introduit sur la première phase de cette introduction


# Comment ajouter un utilisateur avec login/mot de passe?

ajouter une ligne comme `foo:123:1002:100:upload` dans le fichier [users.conf](./users.conf), avec

- foo : représente le login souhaité
- 123 : le mot de passe souhaité
- 1002 : l'identifiant user que le service/container sftp doit attribuer à l'utilisateur. il doit être unique (ne pas attribuer ou avoir un même numéro attribué à plus d'un utilisateur sur ce fichier)
- 100 : le groupe d'appartenance dans le système d'exploitation ou container. vous pouvez garder le même numéro de groupe `100` pour tous les utilisateurs.
- upload : le repertoire principale, qui sera automatiquement créé pour l'utilisateur correspondant. même si un nom de repertoire identique a déjà été associé à un autre utilisateur, cela ne pose pas problème. En r
éalité cela sera un sous repetoire du dossier /home/NomDeL'utilisateur/upload

## Mot de passe en claire

Le mot de passe peut être en clair comme le `123` dans `foo:123:1002:100:upload`  : l'inconvénient est donc le fait que tout le monde qui a accès à ce projet peut savoir le mot de passe utiliser pour l'utilisateur
en question.

## Mot de passe crypté

On peut crypter le mot de passe avec cette commande (par exemple pour crypter la valeur `123` comme mot de passe) :

```sh
echo -n "123" | docker run -i --rm atmoz/makepasswd --crypt-md5 --clearfrom=-
```

Cela donnera quelque chose comme :

```sh
123   $1$OYvRvaUW$KXaBpHsEd5vAcBG.dBjkk/
```

à gauche `1232`, c'est un rappel de ce qu'a été demandé, et à droite `$1$OYvRvaUW$KXaBpHsEd5vAcBG.dBjkk/` sa valeur cryptée.

Ainsi au lieu d'avoir la ligne `foo:123:1002:100:upload` dans le fichier [users.conf](./users.conf), on peut avoir plutôt cette ligne : `foo:$1$OYvRvaUW$KXaBpHsEd5vAcBG.dBjkk/:e:1002:100:upload` . Les différences e
ntre ces deux lignes sont :

- on a `$1$OYvRvaUW$KXaBpHsEd5vAcBG.dBjkk/` à la place `123`
- il y a le `:e` sur la 2ème ligne, juste après le mot de passe crypté

Une fois le mot de passe crypté, vous pouvez l'utiliser dans le fichier et enregistrer le fichier ou projet où vous souhaitez (git, drive...) sans trop craindre que quelqu'un d'autre puisse déviner le vrai mot de p
asse qui se cache derrière. Sauf si vous choisissez des mots simple comme '123', 'hello', 'root', 'rootroot'... (qui sont facilement dévinable, avec ou sans cryptage)

# Comment ajouter un utilisateur avec login/clé ssh

Réaliser d'abord l'étape de création de compte avec login/mot de passe. Puis :

Un même utilisateurt peut avoir une ou plusieurs clés ssh, par exemple s'il veut pouvoir se connecter sur le sftp de puis plusieurs sources/ordinateurs/serveurs différents.

Il suffit de créer un fichier dont le nom porte le nom de la source en question , exe monpc1_blabla_toto.xyz (n'importe quelle extension ou pas d'extension du tout, cela n'a pas d'importance). Et copier dans ce fic
hier la clé ssh publique de l'utilisateur issue de la source en question.

tous les contenus de tous les fichiers se trouvant dans keys/nomUtilisateur seront ajoutés dans le dossier .ssh/authorized_keys de l'utilisateur (fusionnés) : chaque fichier sera écrit dans une nouvelle ligne dans
le .ssh/authorized_keys
Donc il n'est pas utile d'ajouter plus d'uné clé ssh publique dans un fichier dans keys : c'est préférable de créer plutôt un fichier pa clé ssh publique

# Remarques & FAQ

## Comment faire en sorte que plusieurs compte partagent le même dossier?

Il suffit de faire des montages volumes qui pointent vers la même destination du **host** depuis les dossiers des **home** des utilisateurs en questions


Exemples:

```sh
 volumes:
    - ${PWD}/data/dossierCommun:/home/utilisateur1/upload:rw
    - ${PWD}/data/dossierCommun:/home/utilisateur2/upload:rw
    - ${PWD}/data/dossierCommun:/home/foo/upload:rw
```

# TODO

[] comment faire que le dossier .ssh ne soit pas visible sur le sftp