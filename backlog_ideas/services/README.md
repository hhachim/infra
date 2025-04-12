# Services

docker-compose.yaml containing base stack to run wynd applications.

# Description

> Traefik 2.4
> Percona Mysql 5.7
> Elastic Search 5.3.0
> Elastic Search 8.13
> Maildev
> PhpMyAdmin
> Rabbit MQ 3.7
> Redis 6.0
> Redis Commander
> SFTP
> Postgresql 16

## Installation / Setup

- Copy `.env.dist` file to `.env`

```bash
cp .env.dist .env
```

- You have to edit some variable in `.env` file.
- `HOST_IP=127.0.0.1` : use "127.0.0.1" by default, or your **docker-machine** IP if you are using this solution (maybe on macOS)


If you have a Mac M1 :

- Copy past `docker-compose.override.yaml.dist` to `docker-compose.override.yaml` it will enable different platform for mysql containers, otherwise u will not up this containers.


```yaml
# Config Platform for Mac M1
services:
    mysql:
        platform: linux/amd64
    mysql80:
        platform: linux/amd64

```

- And then run the `docker compose`

```bash
docker compose --env-file .env up -d
```

- or for minimal API dependencies


```bash
docker compose --env-file .env up -d traefik mysql mysql80 sftp redis rabbitmq
```

If you obtain this error:
```bash
ERROR: Get https://docker-push.wynd.eu/v2/graviteeio/management-api/manifests/1.29.6: no basic auth credentials
```
you need fill your credentials with a docker login:
```bash
docker login docker-push.wynd.eu
```

## Frontends

Traefik is used as a reverse proxy in order to be able to browse the different web applications

Here are the different urls to the services :

- http://traefik.127.0.0.1.traefik.me
- http://pma.127.0.0.1.traefik.me
- http://rabbitmq.127.0.0.1.traefik.me
- http://maildev.127.0.0.1.traefik.me
- http://redis-commander.127.0.0.1.traefik.me

(if your HOST_IP variable is 127.0.0.1)

## Default credentials

See .env file to see the different passwords
If you want to change them, edit the .env file and run `docker compose --env-file .env up yourservice youwant`

## SFTP

- host : HOST_IP
- port : 2222
- username : (see .env file)
- password : (see .env file)
- id_user : (put your id user value with next cmd value `id -u`)
- id_group : (put your group user value with next cmd value `id -g`)
