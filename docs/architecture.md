# Architecture et configuration

Microstack IA utilise deux projets Compose. `docker-compose.dockhand.yml` est lancé sur l'hôte par `scripts/deploy-dockhand.sh` ; il contient seulement Dockhand. `docker-compose.yml` est chargé depuis Git dans Dockhand et contient Coolify, ses dépendances, T3 Code et Beszel. Le bootstrap doit précéder le déploiement Git : il crée le réseau et les fichiers d'environnement utilisés par les deux projets.

## Services et réseaux

| Service | Image | Réseaux | Accès publié sur l'hôte |
| --- | --- | --- | --- |
| Dockhand | `fnsys/dockhand:latest` | `microstack-control` | `127.0.0.1:8000 → 3000` |
| MCP Dockhand | `ghcr.io/strausmann/mcp-dockhand:latest` | `microstack-control` | Aucun ; `mcp-dockhand:8080` en interne |
| Coolify | `coollabsio/coolify:latest` | `coolify`, `microstack-control` | Aucun |
| PostgreSQL | `postgres:latest` | `coolify` | Aucun |
| Redis | `redis:latest` | `coolify` | Aucun |
| T3 Code | `ghcr.io/dizys/t3code-docker:latest` | `microstack-control` | `127.0.0.1:8003 → 8080` (interface et `/__setup`) |
| Beszel | `henrygd/beszel:latest` | `monitoring`, `microstack-control` | `127.0.0.1:8002 → 8090` |
| Beszel Agent | `henrygd/beszel-agent:latest` | `monitoring` | Aucun ; profil `monitoring-agent` |

Tous les ports de ce tableau sont liés à `127.0.0.1`. Depuis T3, les noms `dockhand:3000`, `coolify:8080` et `beszel:8090` passent par `microstack-control`, créé par le bootstrap en réseau externe. Le réseau `coolify` relie l'application à `postgres` et `redis` ; `monitoring` relie Beszel à `beszel-agent`. T3 n'est pas sur ces deux réseaux. `host.docker.internal` est défini pour Coolify et T3, mais un service lié au loopback de l'hôte n'est pas automatiquement accessible par cette adresse depuis un conteneur.

Coolify attend que PostgreSQL et Redis soient sains avant de démarrer. Ses contrôles vérifient `/api/health` et le service temps réel sur le port 6001 ; T3 vérifie le port unifié 8080 ; Beszel et son agent utilisent leurs commandes `health`. Un état sain indique seulement que le contrôle configuré réussit.

## Variables de la stack Git

| Variable | Valeur par défaut | Effet |
| --- | --- | --- |
| `T3_SETUP_KEY` | Vide | Clé de Setup ; vide laisse l'image générer et conserver une clé. |
| `STACK_DOMAIN` | Obligatoire | Domaine sans protocole ; Compose dérive les URL publiques de Coolify, T3 et Beszel. Les routes et règles Cloudflare sont configurées séparément. |
| `DOCKHAND_API_TOKEN` | Obligatoire | Jeton personnel Dockhand pour l'accès du serveur MCP à l'API. |
| `DOCKHAND_MCP_TOKEN` | Obligatoire | Secret distinct requis pour accéder au serveur MCP Dockhand. |
| `BESZEL_AGENT_KEY` | Vide | Clé publique fournie par le hub Beszel à son agent. |
| `COMPOSE_PROFILES` | Vide | Mettre `monitoring-agent` après avoir défini `BESZEL_AGENT_KEY` pour démarrer l'agent. |

Ces variables sont définies dans Dockhand. Les secrets Coolify ne sont pas définis ici : ils sont lus à partir de `/data/coolify/source/.env` sur l'hôte. Le script conserve ce fichier s'il existe déjà ; il régénère `/data/coolify/source/t3code.env` avec l'identité du socket. Dockhand monte `/data/coolify` en lecture seule pour que son processus Compose puisse lire ces fichiers.

Le bootstrap crée des dossiers sous `/data/coolify` avec UID 9999 et groupe 0. Il génère notamment les valeurs Coolify `APP_KEY`, `DB_PASSWORD`, `REDIS_PASSWORD` et `PUSHER_*`. PostgreSQL traduit les variables `DB_USERNAME`, `DB_DATABASE` et `DB_PASSWORD` du fichier Coolify en variables d'initialisation `POSTGRES_*`. Redis utilise `REDIS_PASSWORD`. Les changements d'identifiants ne migrent pas automatiquement les données ou les utilisateurs d'une base existante.

Les noms publics et routes vers les ports locaux sont détaillés dans [Cloudflare Tunnel](cloudflare.md). `T3_PUBLIC_URL` et l'`APP_URL` Beszel utilisent le domaine ; Coolify reçoit son `APP_URL`, le nom Reverb, le port public 443 et le port de terminal public 443. Cloudflare Tunnel transmet `/app/…` au port local 6001, `/terminal/ws` au port 6002 et les autres requêtes au port 8001. Ces valeurs ne créent pas les DNS ou politiques Access et ne remplacent pas les réglages persistants des interfaces.

## Données persistantes

| Données | Stockage |
| --- | --- |
| Configuration Dockhand | Volume `dockhand-data` → `/app/data` |
| Configuration et données Coolify | Sous-dossiers de `/data/coolify`, montés dans Coolify |
| Base Coolify | Volume explicitement nommé `coolify-db` → `/var/lib/postgresql` |
| Redis Coolify | Volume explicitement nommé `coolify-redis` → `/data` |
| T3 | `t3code-home`, `t3code-workspace`, `t3code-services` ; voir [T3](assistant-ia.md) |
| Beszel | `beszel-data` → `/beszel_data`, `beszel-agent-data` → `/var/lib/beszel-agent` |

Les noms effectifs des volumes sans `name:` dépendent du nom du projet Compose. Préserver les volumes et sauvegarder le fichier Coolify avec les données : l'`APP_KEY` existante est nécessaire à la lecture des secrets chiffrés par Coolify. Voir [sauvegardes et migration](exploitation.md#migration-dune-installation-existante).

## Fichiers du dépôt

| Fichier | Rôle |
| --- | --- |
| `scripts/deploy-dockhand.sh` | Prépare les fichiers hôte et démarre Dockhand. |
| `docker-compose.dockhand.yml` | Projet du bootstrap Dockhand. |
| `docker-compose.yml` | Stack Git déployée depuis Dockhand. |
| `.github/workflows/validate.yml` | Validation Compose et syntaxe du script dans la CI. |
