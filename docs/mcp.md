# Les MCP de Microstack IA

T3 Code et les agents s'exécutent dans `t3code`, sur le réseau Docker `microstack-control`. Depuis ce conteneur, Coolify répond sur `coolify:8080`, Dockhand sur `dockhand:3000` et Beszel sur `beszel:8090`. Ces noms ne sont valables que sur ce réseau. Depuis le poste de l'utilisateur, les interfaces passent par le tunnel SSH décrit dans le [README](../README.md).

## Coolify

Coolify expose un serveur MCP Streamable HTTP sur `/mcp`. Dans cette stack, l'adresse interne à ajouter à la configuration de l'agent est :

```text
http://coolify:8080/mcp
```

Sur une instance auto-hébergée, le serveur est désactivé au départ : dans Coolify, **Settings → Advanced → API and MCP**, activer **MCP server**. Tant qu'il est désactivé, `/mcp` répond 404. Vérifier aussi l'accès MCP de l'équipe et les adresses IP autorisées si une liste existe. Créer un jeton API pour l'équipe avec les permissions nécessaires, puis configurer l'en-tête `Authorization: Bearer <jeton>` dans le client. Les permissions du jeton déterminent les ressources et opérations accessibles ; les suppressions exigent la permission `delete`. La documentation amont demande une URL HTTPS publique pour l'installation auto-hébergée : l'adresse HTTP interne ci-dessus correspond au réseau Docker de cette stack et doit être vérifiée avec le client utilisé ; en cas de refus ou de contrainte de sécurité du client, utiliser une URL HTTPS configurée pour Coolify.

Dans **Setup → MCP servers** de T3, ajouter l'URL Streamable HTTP, renseigner l'en-tête et appliquer l'entrée aux agents souhaités. L'agent peut aussi l'ajouter à sa propre configuration native. Démarrer une nouvelle session et appeler `get_infrastructure_overview` pour vérifier la connexion et les ressources accessibles. Une entrée enregistrée ne prouve pas que la connexion fonctionne. Les jetons et les en-têtes restent dans la configuration privée de l'agent ; ne pas les mettre dans Git ou les journaux.

Si `/mcp` répond 404, vérifier que le MCP est activé et que l'image Coolify utilisée fournit cette fonctionnalité. En cas de refus, vérifier le jeton, les permissions de l'équipe et l'allowlist. Les jetons restent soumis aux droits de leur propriétaire. Voir [Setup MCP](https://coolify.io/docs/mcp/setup) et [permissions](https://coolify.io/docs/api/permissions).

## Navigateurs pour les agents

`ghcr.io/dizys/t3code-docker:latest` inclut les serveurs MCP Playwright et Chrome DevTools. Après installation des agents, exécuter dans le terminal du conteneur T3 :

```sh
t3-browser-mcp
```

Cette commande inscrit Playwright dans la configuration native des agents pris en charge. Pour Chrome DevTools avec Claude :

```sh
t3-browser-mcp --server chrome-devtools --harness claude
```

Ouvrir une nouvelle session après modification. Les navigateurs MCP permettent d'accéder aux interfaces Dockhand, Coolify et Beszel aux adresses internes ci-dessus ; ils ont leur propre session et ne récupèrent pas la connexion du navigateur personnel. Chrome DevTools avec Chromium est moins éprouvé que Playwright. Les commandes, options et restrictions sont détaillées dans le [guide navigateur de l'image](https://github.com/dizys/t3code-docker/blob/main/docs/agent-browser.md).

## Serveur MCP T3 Code

T3 Code expose lui-même un serveur `/mcp` pour un agent externe. Dans **Settings → Environments**, copier l'URL fournie et suivre l'authentification OAuth. Depuis l'extérieur de Docker, utiliser un tunnel ou une adresse HTTPS/T3 Connect accessible au client. Ce serveur donne accès à l'environnement T3 ; il ne remplace pas le MCP Coolify. Voir [Outside agents](https://github.com/pingdotgg/t3code/blob/main/docs/user/outside-agents.md).

## Dockhand, Beszel et Docker

Dockhand est accessible sur `http://dockhand:3000` et Beszel sur `http://beszel:8090` depuis T3. Leurs interfaces permettent à l'agent navigateur d'interagir avec les services après connexion. Dockhand référence aussi un [serveur MCP communautaire](https://dockhand.pro/manual/) séparé ; le Compose de ce dépôt ne le déploie pas. Beszel expose une [API REST](https://beszel.dev/guide/rest-api), dont l'URL n'est pas un serveur MCP.

T3 monte `/var/run/docker.sock` : son agent peut joindre directement l'API Docker, sous réserve des permissions du socket. L'image ne garantit pas la commande `docker` ; ce contrôle utilise `curl` :

```sh
curl --unix-socket /var/run/docker.sock http://localhost/_ping
```

Un résultat `OK` confirme l'accès au démon, pas la présence d'un serveur MCP Docker. Cet accès permet l'administration de l'hôte.

## Où T3 conserve la configuration

Les définitions partagées de Setup sont dans `/home/t3/.t3/setup/mcp/servers.json` ; elles sont appliquées aux configurations natives des agents sélectionnés. Les réglages et leurs éventuelles sauvegardes peuvent contenir des secrets et résident dans le volume `t3code-home`. Une mise à jour par Setup ne démarre pas le serveur et une session déjà ouverte ne recharge pas nécessairement ses MCP. Pour les emplacements natifs par agent et l'authentification OAuth, voir la [documentation MCP de l'image](https://github.com/dizys/t3code-docker/blob/main/docs/mcp-servers.md).
