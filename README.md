# Microstack IA

Socle auto-hébergé pour une entreprise : Coolify pour déployer des sites et applications, Beszel pour la supervision et T3 Code pour piloter des agents et proposer son serveur MCP. Les applications restent libres de leurs fournisseurs d'IA. Inspiré de la structure d'exploitation de la stack VPS de FRFlo.

> **État : chantier initial.** La configuration Compose est validée syntaxiquement et la CLI T3 Code a été démarrée localement, mais la construction des images, le démarrage complet de la stack, les déploiements Coolify et l'accès HTTPS n'ont pas encore été validés. Ne pas utiliser en production en l'état.

## Contenu

| Chemin | Rôle |
| --- | --- |
| `docker-compose.yml` | Coolify, PostgreSQL, Redis, Beszel et profils facultatifs pour T3 Code et l’agent Beszel. |
| `scripts/setup-secrets.sh` | Initialisation unique des secrets et des dossiers Coolify. |
| `docs/exploitation.md` | Réseau, domaines, supervision, mises à jour et sauvegardes. |
| `.github/` | Modèles de contribution GitHub. |

Le fichier Compose s'inspire de ceux de [Coolify v4.7.5](https://github.com/coollabsio/coolify/tree/v4.7.5), distribué sous licence Apache 2.0. Les images tierces ont leurs propres licences.

## Prérequis

Serveur Linux dédié ou vérifié compatible, Docker Engine et plugin Docker Compose, OpenSSL, accès administrateur et un nom de domaine. Coolify doit pouvoir se connecter au serveur cible par SSH pour effectuer les déploiements. Prévoir DNS, ports TCP 80 et 443 et une sauvegarde externe. Le domaine et l'adresse IP ne sont pas fournis par ce projet.

## Préparation expérimentale

Depuis le dossier du projet sur le serveur :

```sh
sudo ./scripts/setup-secrets.sh
sudo docker compose --env-file /data/coolify/source/.env config
sudo docker compose --env-file /data/coolify/source/.env up -d
```

Le script refuse de remplacer une configuration existante et ne doit pas servir à reprendre une installation Coolify déjà présente. Il génère `/data/coolify/source/.env` ; sauvegardez ce fichier hors du serveur. Les domaines et certificats des applications sont configurés dans Coolify et dans le DNS ; voir [exploitation](docs/exploitation.md).

Les interfaces Coolify (`8000`) et Beszel (`8002`) écoutent uniquement sur l'interface locale du serveur. Pour un premier accès, ouvrez un tunnel SSH depuis votre poste :

```sh
ssh -L 8000:127.0.0.1:8000 -L 8002:127.0.0.1:8002 utilisateur@serveur
```

Ouvrez ensuite `http://localhost:8000` et `http://localhost:8002` sur votre poste et créez les comptes administrateurs immédiatement. L'accès public et les WebSockets Coolify doivent encore être validés avant exposition. La connexion SSH du serveur à Coolify doit être configurée et vérifiée dans l'interface avant tout déploiement.

## T3 Code et agents

Pour activer T3 Code et son moteur Docker dédié :

```sh
sudo docker compose --env-file /data/coolify/source/.env --profile agents up -d --build
```

Ajouter `-L 8021:127.0.0.1:8021` au tunnel SSH présenté plus haut, puis ouvrir `http://localhost:8021`. Les instructions d'appairage figurent dans les journaux de T3 Code. Connectez Codex et/ou Claude Code avec leur propre compte ou méthode de connexion depuis le conteneur :

```sh
sudo docker compose --env-file /data/coolify/source/.env --profile agents exec t3code codex login
sudo docker compose --env-file /data/coolify/source/.env --profile agents exec t3code claude auth login
```

Suivre les instructions affichées, sans transmettre de code ou de secret dans une issue. Les identifiants sont conservés dans le volume personnel de T3 Code. T3 Code inclut un serveur MCP OAuth sur `/mcp`.

## État et commandes

```sh
sudo docker compose --env-file /data/coolify/source/.env ps
sudo docker compose --env-file /data/coolify/source/.env logs --tail=100
```

Ne partagez pas de journaux contenant des secrets. Voir les [instructions de contribution](CONTRIBUTING.md). Licence du projet : [Apache 2.0](LICENSE).
