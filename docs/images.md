# Images et limites de la stack

Ce guide décrit les choix de `docker-compose.yml` et de `docker-compose.dockhand.yml` par rapport aux images utilisées. Tous les tags sont `latest` : leur contenu évolue au prochain téléchargement. Les réseaux, variables et volumes figurent dans [architecture](architecture.md).

## Dockhand

L'[exemple officiel](https://github.com/Finsys/dockhand/blob/main/docker-compose.yaml) utilise `fnsys/dockhand:latest`, le socket Docker et `/app/data` persistant, comme ce dépôt. Ici le port est limité à l'interface locale et le réseau partagé permet l'accès depuis T3. L'intégration Git, les sauvegardes et la synchronisation doivent être configurées dans Dockhand ; la présence de l'image ne les active pas. Vérifiez les conditions de licence du projet pour votre usage.

## Coolify, PostgreSQL et Redis

Les fichiers [Compose de base](https://github.com/coollabsio/coolify/blob/main/docker-compose.yml) et [production](https://github.com/coollabsio/coolify/blob/main/docker-compose.prod.yml) définissent les volumes, les contrôles de santé et les ports de Coolify. Ce dépôt reprend leur structure et utilise des variables chargées depuis le fichier généré par le bootstrap. Il ne lance pas l'installateur officiel complet : initialisation de l'accès SSH aux serveurs, proxy, DNS et autres réglages d'exploitation peuvent nécessiter des étapes supplémentaires dans Coolify. Le proxy `nginx:latest` route l’interface, Reverb et le terminal sur le seul port hôte 8001 ; Coolify conserve ses ports internes 8080, 6001 et 6002.

**Écart de versions :** les fichiers officiels utilisent `postgres:15-alpine` et `redis:7-alpine`, alors que ce dépôt utilise `postgres:latest` et `redis:latest`. Cela répond au choix de versions flottantes mais ne prouve pas que les nouvelles versions majeures sont compatibles avec Coolify. Consultez l'amont et sauvegardez avant toute mise à jour. Une nouvelle version majeure PostgreSQL nécessite une migration explicite ; ne redéployez pas aveuglément une base existante. Voir les [instructions de migration](exploitation.md#migration-dune-installation-existante) et la [documentation de l'image PostgreSQL](https://github.com/docker-library/docs/blob/master/postgres/README.md).

Depuis PostgreSQL 18, le volume est monté sur `/var/lib/postgresql`. Les variables d'initialisation de l'image PostgreSQL ne modifient pas une base déjà initialisée : changer un mot de passe dans le fichier d'environnement ne change pas à lui seul le mot de passe stocké dans PostgreSQL. Redis persiste ses données dans `/data` et utilise un mot de passe ; consultez la [documentation de l'image Redis](https://github.com/docker-library/docs/blob/master/redis/README.md) et évaluez la compatibilité de son format de persistance avant changement de version majeure.

## T3 Code

L'[image `latest`](https://github.com/dizys/t3code-docker) est la variante navigateur. La stack monte les trois emplacements persistants recommandés, expose les deux ports sur loopback, et reprend `shm_size` et le délai d'arrêt recommandés. Les agents et chaînes d'outils s'installent en arrière-plan au premier démarrage ; le volume de services permet de conserver les services optionnels sans les installer automatiquement. Sans `T3_SETUP_KEY` explicite, l'image génère une clé conservée dans le volume et affichée dans ses journaux. Consultez les journaux dans Dockhand sans les partager.

La page Setup permet notamment de gérer fournisseurs, MCP, mises à jour et services optionnels. Les fonctions SSH, Tailscale et Cloudflare demandent une installation et une configuration propres ; elles ne sont pas activées par ce dépôt. Voir [configuration](https://github.com/dizys/t3code-docker/blob/main/docs/configuration.md), [services](https://github.com/dizys/t3code-docker/blob/main/docs/services.md) et [MCP](mcp.md). Le navigateur intégré à T3 et les MCP navigateur sont distincts.

## Beszel

Le [hub officiel](https://github.com/henrygd/beszel/blob/main/supplemental/docker/hub/docker-compose.yml) utilise `/beszel_data` et l'agent `/var/lib/beszel-agent` avec le socket Docker. L'[exemple officiel de l'agent](https://github.com/henrygd/beszel/blob/main/supplemental/docker/agent/docker-compose.yml) utilise le réseau hôte, contrairement au réseau bridge retenu ici pour joindre `beszel-agent` depuis le hub par son nom. Certaines statistiques, en particulier réseau, peuvent donc différer de celles de l'hôte. Les variantes GPU, disques supplémentaires, `HUB_URL` et `TOKEN` sont des options séparées, à configurer selon la [documentation Beszel](https://beszel.dev/guide/agent-installation) et le mode de connexion choisi. La stack actuelle fournit la clé publique et utilise la connexion du hub vers l'agent ; elle ne configure pas l'enregistrement initié par l'agent.
