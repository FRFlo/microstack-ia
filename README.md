# Microstack IA

Stack auto-hébergée déployée depuis Git avec Dockhand, Beszel pour la supervision et T3 Code pour piloter des agents et proposer son serveur MCP.

> **État : chantier initial.** Le déploiement complet et l'accès HTTPS restent à valider sur un serveur.

## Fichiers

| Chemin | Rôle |
| --- | --- |
| `docker-compose.dockhand.yml` | Dockhand seul, pour le démarrage initial sur le serveur. |
| `scripts/deploy-dockhand.sh` | Démarrage initial de Dockhand via SSH. |
| `docker-compose.yml` | Coolify, PostgreSQL, Redis, Beszel et profils facultatifs ; à ajouter dans Dockhand depuis Git. |
| `docs/exploitation.md` | Supervision, accès réseau et sauvegardes. |

Les images tierces ont leurs propres licences.

## Prérequis

Serveur Linux, Docker Engine, plugin Docker Compose et accès SSH avec droits sudo. Prévoir DNS, ports TCP 80 et 443 si les services sont publiés par un proxy, et une sauvegarde externe.

## Démarrage initial de Dockhand

Sur le serveur, cloner le dépôt puis démarrer Dockhand :

```sh
ssh utilisateur@serveur
git clone <URL_DU_DEPOT> microstack-ia
cd microstack-ia
sudo ./scripts/deploy-dockhand.sh
```

Le script prépare aussi les secrets et dossiers de Coolify sous `/data/coolify`. Sauvegarder `/data/coolify/source/.env` hors du serveur. Dockhand écoute uniquement sur `127.0.0.1:8000`. Depuis un second terminal local, ouvrir les tunnels SSH :

```sh
ssh -L 8000:127.0.0.1:8000 -L 8001:127.0.0.1:8001 -L 8002:127.0.0.1:8002 utilisateur@serveur
```

Ouvrir `http://localhost:8000`, créer le compte administrateur, puis ajouter la stack depuis le dépôt Git et choisir `docker-compose.yml`. Coolify sera accessible sur `http://localhost:8001` et Beszel sur `http://localhost:8002`. Dockhand déploiera et mettra ensuite à jour la stack selon sa configuration Git. Le volume `dockhand-data` conserve sa configuration.

## T3 Code et agents

Définir `COMPOSE_PROFILES=agents` dans les variables de la stack Dockhand pour démarrer T3 Code. Ajouter `-L 8003:127.0.0.1:8003` au tunnel SSH pour y accéder. Les instructions d'appairage figurent dans les journaux de T3 Code. Ouvrir une console dans le conteneur T3 Code depuis Dockhand et lancer la connexion souhaitée :

```sh
codex login
claude auth login
```

Suivre les instructions affichées, sans transmettre de code ou de secret dans une issue. Les identifiants sont conservés dans le volume personnel de T3 Code. T3 Code inclut un serveur MCP OAuth sur `/mcp`.

Voir [exploitation](docs/exploitation.md) pour la supervision, les sauvegardes et les accès réseau. Ne partagez pas de journaux contenant des secrets. Licence du projet : [Apache 2.0](LICENSE).
