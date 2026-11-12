# T3 Code dans Microstack IA

La stack démarre `ghcr.io/dizys/t3code-docker:latest` sans profil Compose. Son interface écoute sur `127.0.0.1:8003` et Setup sur `127.0.0.1:8004` de l'hôte ; le tunnel du [README](../README.md) rend ces ports accessibles sur le poste. Au premier démarrage, l'image installe les agents et les outils par défaut en arrière-plan dans le volume personnel. La page Setup affiche leur progression et permet de connecter les fournisseurs.

| Montage Compose | Chemin dans T3 | Contenu |
| --- | --- | --- |
| `t3code-home` | `/home/t3` | État T3, conversations, configurations MCP, connexions, agents et outils installés. |
| `t3code-workspace` | `/workspace` | Dépôts et projets ouverts dans T3. |
| `t3code-services` | `/var/lib/t3code/services` | Logiciels et identités des services optionnels T3. |
| Socket hôte | `/var/run/docker.sock` | API Docker de l'hôte. |

Les noms Docker réels des trois volumes nommés dépendent du nom de projet Compose choisi dans Dockhand. Le volume de services conserve les services optionnels lorsqu'ils sont installés ; sa présence n'active ni SSH, ni Tailscale, ni Cloudflare.

## Accès et identité

`T3_SETUP_KEY` peut être fourni dans les variables sensibles de la stack Dockhand. Si cette valeur est vide, l'image génère une clé persistée dans le volume personnel et l'affiche au premier démarrage dans les journaux T3. Une session T3 autorisée avec accès au terminal peut aussi accéder à Setup selon la configuration par défaut de l'image.

Le bootstrap écrit `/data/coolify/source/t3code.env` avec `PUID=1000` et `PGID` égal au groupe du socket Docker au moment de son exécution. T3 utilise cette identité pour accéder au socket si ses permissions l'autorisent. Si le groupe du socket change, relancer le bootstrap puis recréer T3 depuis Dockhand. Les commandes lancées par un agent qui peut utiliser l'API Docker peuvent contrôler l'hôte.

## Dépôt et déploiement

Dockhand possède sa copie du dépôt Git pour déployer `docker-compose.yml`. Le volume `/workspace` est distinct : cloner ou ouvrir ce dépôt dans T3 pour que l'agent dispose des fichiers, de `AGENTS.md` et de cette documentation. Modifier cette copie ne change pas la stack active. Les changements doivent parvenir à la branche Git suivie par Dockhand, puis être synchronisés et redéployés selon les réglages de la stack. Une synchronisation automatique doit être configurée dans Dockhand.

## Accès des agents aux services

Le réseau `microstack-control` relie T3, Dockhand, Coolify et Beszel. [Les MCP de la stack](mcp.md) décrivent l'URL Coolify, son authentification, les navigateurs MCP et le socket Docker. Chaque agent charge sa propre configuration ; l'activation dans Setup ou dans un fichier ne modifie pas nécessairement les sessions déjà ouvertes.

Un premier message possible dans T3 :

> Lis `AGENTS.md` et les guides de ce dépôt. Configure les accès utiles à cette stack en suivant `docs/mcp.md`, puis aide-moi à terminer la mise en service de Coolify et Beszel. Prends en compte les volumes existants et indique les connexions ou autorisations que je dois effectuer.

Les comptes Coolify, Beszel et les fournisseurs IA sont propres à l'installation. Une session de navigateur dans T3 ne partage pas la session du poste de l'utilisateur.
