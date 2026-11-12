# Microstack IA

Stack auto-hébergée pilotée depuis Git avec Dockhand, Coolify, Beszel et T3 Code. L'objectif est de démarrer Dockhand par SSH, d'y ajouter ce dépôt, puis de confier la configuration et l'exploitation à un agent IA, avec votre assistance pour les comptes et autorisations.

> Le déploiement complet reste à valider sur votre serveur. Si la stack existe déjà, lire les [consignes de migration](docs/exploitation.md#migration-dune-installation-existante) avant de recréer les conteneurs.

## Démarrage

Prérequis : serveur Linux avec Docker Engine, plugin Docker Compose, OpenSSL, Git et accès SSH avec sudo. Sur le serveur :

```sh
git clone <URL_DU_DEPOT> microstack-ia
cd microstack-ia
sudo ./scripts/deploy-dockhand.sh
```

Le script démarre Dockhand, crée le réseau partagé et prépare les dossiers et secrets Coolify dans `/data/coolify`. Il conserve les secrets Coolify existants. Sauvegardez `/data/coolify/source/.env` hors du serveur : ce fichier est lu directement par la stack, il ne faut pas recopier ses secrets dans Dockhand.

Depuis votre poste, ouvrez les tunnels SSH :

```sh
ssh -L 6001:127.0.0.1:6001 -L 6002:127.0.0.1:6002 -L 8000:127.0.0.1:8000 -L 8001:127.0.0.1:8001 -L 8002:127.0.0.1:8002 -L 8003:127.0.0.1:8003 -L 8004:127.0.0.1:8004 utilisateur@serveur
```

1. Ouvrez `http://localhost:8000`, créez le compte administrateur Dockhand et un jeton personnel dans son profil, puis ajoutez ce dépôt comme stack Git en choisissant `docker-compose.yml`.
2. Dans les variables sensibles de la stack, définissez `DOCKHAND_API_TOKEN` avec ce jeton et `DOCKHAND_MCP_TOKEN` avec un secret aléatoire distinct. Définissez si souhaité `T3_SETUP_KEY` pour protéger la configuration T3, puis déployez la stack. Le fichier `/data/coolify/source/t3code.env`, créé par le script et lu par Dockhand, configure les identifiants d'accès au socket Docker. Le [guide MCP](docs/mcp.md#dockhand) décrit la connexion de l'agent.
3. Ouvrez la configuration T3 sur `http://localhost:8004`, récupérez la clé générée dans les journaux T3 si `T3_SETUP_KEY` est vide, installez les agents souhaités et connectez leurs fournisseurs. Les installations initiales se terminent en arrière-plan. Ouvrez T3 sur `http://localhost:8003`, ajoutez ou clonez ce dépôt dans un projet, puis utilisez le [prompt de démarrage](docs/assistant-ia.md).
4. Créez vos comptes Coolify et Beszel sur les ports 8001 et 8002. Pour superviser le serveur avec Beszel Agent, suivez les étapes du [guide d'exploitation](docs/exploitation.md#beszel).

Les comptes, connexions aux fournisseurs IA, autorisations OAuth et clé Beszel demandent une action humaine. L'agent peut ensuite aider à configurer et exploiter la stack selon les accès accordés.

## Guides

- [Architecture, réseaux, variables et volumes](docs/architecture.md)
- [T3 Code et agents dans la stack](docs/assistant-ia.md)
- [MCP de la stack et accès des agents](docs/mcp.md)
- [Exploitation, ports, sauvegardes et migration](docs/exploitation.md)
- [Compatibilité et capacités des images](docs/images.md)
- [Instructions pour les agents](AGENTS.md)

Les images tierces ont leurs propres licences. Licence du projet : [Apache 2.0](LICENSE).
