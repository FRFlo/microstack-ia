# Accès par Cloudflare Tunnel

Comme dans la stack VPS, `cloudflared` fonctionne sur l'hôte et transmet les noms publics aux ports liés à `127.0.0.1`. Dockhand reste installé séparément de la stack Git : le tunnel doit donc rester indépendant de celle-ci. Les routes Cloudflare, leurs DNS et les règles Access sont configurés dans le compte Cloudflare ; Compose ne les crée pas.

## Domaine de la stack

Dans les variables de la stack Git Dockhand, définir **`STACK_DOMAIN`**, sans protocole ni barre finale, par exemple `example.com`. Choisir une zone déjà gérée par Cloudflare et dont les sous-domaines ci-dessous sont disponibles. Cette valeur est la référence du dépôt : Compose en déduit les URL publiques de T3, Beszel et Coolify et le nom temps réel de Coolify. Les routes, DNS et applications Access restent à créer dans Cloudflare avec la même valeur ; changer la variable ne les modifie pas automatiquement. Le domaine propre aux applications déployées ensuite par Coolify se configure dans Coolify et Cloudflare selon leurs besoins.

| Nom public | Destination du connecteur installé sur l'hôte | Usage |
| --- | --- | --- |
| `dockhand.<STACK_DOMAIN>` | `http://127.0.0.1:8000` | Dockhand, y compris avant le déploiement Git |
| `coolify.<STACK_DOMAIN>/terminal/ws` | `http://127.0.0.1:6002` | Terminal Coolify ; route plus spécifique |
| `coolify.<STACK_DOMAIN>` | `http://127.0.0.1:8001` | Interface et MCP Coolify |
| `coolify-realtime.<STACK_DOMAIN>` | `http://127.0.0.1:6001` | WebSocket Reverb Coolify |
| `beszel.<STACK_DOMAIN>` | `http://127.0.0.1:8002` | Interface Beszel |
| `t3.<STACK_DOMAIN>` | `http://127.0.0.1:8003` | Interface T3 et son serveur MCP |
| `t3-setup.<STACK_DOMAIN>` | `http://127.0.0.1:8004` | Configuration T3 |

`127.0.0.1` désigne ici l'hôte où tournent Docker **et** `cloudflared`. Un connecteur dans un conteneur a son propre loopback : il ne peut pas utiliser ces destinations sans configuration réseau adaptée. Les MCP Docker et Dockhand restent sur le réseau Docker interne ; ils n'ont pas de route publique dans ce tableau.

## Mise en place

1. Conserver une session SSH fonctionnelle pour le bootstrap et le dépannage. Lancer `sudo ./scripts/deploy-dockhand.sh` depuis le dépôt : Dockhand écoute sur le port local 8000.
2. Dans Cloudflare, choisir un tunnel existant connecté au même hôte ou créer un tunnel géré à distance, puis installer son connecteur sur cet hôte selon les instructions du tableau de bord. Vérifier qu'il est connecté avant d'ajouter les routes. Un tunnel déjà utilisé par un autre serveur ne donne pas automatiquement accès au loopback de ce serveur : éviter de connecter des machines aux origines différentes au même tunnel sans concevoir le routage.
3. Dans **Networking → Tunnels**, ajouter les routes Published application du tableau. Créer ou vérifier les enregistrements DNS associés, normalement des CNAME proxifiés vers le tunnel. Pour Coolify, placer `/terminal/ws` avant la route générale si l'interface demande un ordre ; la correspondance par chemin doit conserver le chemin. Éviter d'écraser des DNS ou routes déjà utilisés.
4. Dans Cloudflare Zero Trust, créer les applications **Access self-hosted** et leurs règles *Allow* pour les identités autorisées avant de publier les routes. Protéger Dockhand, Coolify, Coolify Realtime, Beszel, T3 et T3 Setup ; limiter T3 Setup et Dockhand aux administrateurs. Vérifier l'ordre des règles et tester avec un compte non autorisé. Tunnel et DNS ne créent pas à eux seuls une authentification Access. Conserver aussi l'authentification native de chaque service.
5. Via `https://dockhand.<STACK_DOMAIN>`, créer l'administrateur puis une stack Git pointant vers `docker-compose.yml`. Saisir `STACK_DOMAIN`, les deux secrets MCP Dockhand et les autres variables nécessaires. Déployer puis configurer les services. Régler l'URL de l'instance Coolify dans son interface sur `https://coolify.<STACK_DOMAIN>` si nécessaire ; une variable d'environnement ne crée ni route Cloudflare ni configuration persistante dans son interface.
6. Vérifier les six noms publics après authentification, puis les WebSockets T3, Beszel et Coolify, les mises à jour en direct et le terminal Coolify. `PUSHER_HOST`, `PUSHER_PORT=443` et `TERMINAL_PORT=443` sont fournis à Coolify par Compose. La route `/terminal/ws` vers 6002 et l'hôte Reverb vers 6001 suivent la [documentation Coolify](https://coolify.io/docs/core/instance-management/reverb-migration). Autoriser les WebSockets sur la zone. Une page de connexion Access renvoyée à un client WebSocket peut empêcher son fonctionnement : adapter l'authentification et tester chaque flux, sans désactiver aveuglément les protections.

Le TLS est terminé chez Cloudflare ; entre `cloudflared` et les ports loopback, ces origines utilisent HTTP. Les ports ne sont pas publiés sur l'interface réseau publique du serveur. Ne pas ouvrir 8000–8004, 6001 ou 6002 sur Internet.

## Clients non interactifs

Les règles Access prévues pour un navigateur peuvent bloquer les clients MCP, les clients mobiles T3 et les webhooks. Définir un accès machine ciblé selon les besoins : par exemple un **service token Access** pour un client capable d'envoyer `CF-Access-Client-Id` et `CF-Access-Client-Secret`, avec une règle Service Auth limitée à l'application concernée. Ne pas exposer ces secrets dans Git ou dans le prompt de l'agent. Si un client ne peut pas envoyer ces en-têtes, choisir une autre voie compatible, par exemple accès interne, WARP ou tunnel privé, en conservant l'authentification propre au service. Tester séparément les connexions navigateur, MCP et WebSocket ; une connexion navigateur autorisée ne prouve pas qu'un client natif fonctionne.

## Modification du domaine ou récupération

Pour changer de domaine, préparer les DNS, certificats et applications Access du nouveau domaine, modifier `STACK_DOMAIN` dans Dockhand puis redéployer. Mettre à jour en parallèle les routes Tunnel et les URL enregistrées dans les interfaces, les clients OAuth et les MCP ; les anciennes URL peuvent rester dans les données persistantes. Vérifier le nouveau parcours avant de retirer l'ancien.

En cas de panne Cloudflare, les ports restent accessibles depuis l'hôte ou par le tunnel SSH du README. L'interface Coolify reste accessible ainsi, mais ses réglages publics Reverb et terminal pointent vers Cloudflare : le temps réel et le terminal ne sont pas garantis par le seul tunnel SSH. Un `502` indique notamment un connecteur ou une origine injoignable ; une page Access inattendue appelle une vérification des applications et politiques ; une interface chargée sans temps réel appelle une vérification des routes et WebSockets. Les services, identifiants et données persistent indépendamment du tunnel.

## Références

- [Cloudflare Tunnel : démarrage et routes](https://developers.cloudflare.com/tunnel/get-started/)
- [Cloudflare Access : applications self-hosted](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted/)
- [Cloudflare Access : service tokens](https://developers.cloudflare.com/cloudflare-one/access-controls/service-credentials/service-tokens/)
- [Coolify : migration Reverb et routes Tunnel](https://coolify.io/docs/core/instance-management/reverb-migration)
