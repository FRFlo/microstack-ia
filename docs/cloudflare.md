# Accès par Cloudflare Tunnel

Comme dans la stack VPS, `cloudflared` fonctionne sur l'hôte et transmet les noms publics aux ports liés à `127.0.0.1`. Dockhand reste installé séparément de la stack Git : le tunnel doit donc rester indépendant de celle-ci. Les routes Cloudflare, leurs DNS et les règles Access sont configurés dans le compte Cloudflare ; Compose ne les crée pas.

## Domaine de la stack

Dans les variables de la stack Git Dockhand, définir **`STACK_DOMAIN`**, sans protocole ni barre finale, par exemple `example.com`. Choisir une zone déjà gérée par Cloudflare et dont les sous-domaines ci-dessous sont disponibles. Cette valeur est la référence du dépôt : Compose en déduit les URL publiques de T3, Beszel et Coolify et le nom temps réel de Coolify. Les routes, DNS et applications Access restent à créer dans Cloudflare avec la même valeur ; changer la variable ne les modifie pas automatiquement. Le domaine propre aux applications déployées ensuite par Coolify se configure dans Coolify et Cloudflare selon leurs besoins.

| Nom public | Destination du connecteur installé sur l'hôte | Usage |
| --- | --- | --- |
| `dockhand.<STACK_DOMAIN>` | `http://127.0.0.1:8000` | Dockhand, y compris avant le déploiement Git |
| `coolify.<STACK_DOMAIN>` avec chemin `^/app/.*` | `http://127.0.0.1:6001` | WebSocket Reverb |
| `coolify.<STACK_DOMAIN>` avec chemin `^/terminal/ws$` | `http://127.0.0.1:6002` | Terminal Coolify |
| `coolify.<STACK_DOMAIN>` (sans chemin) | `http://127.0.0.1:8001` | Interface et MCP Coolify |
| `beszel.<STACK_DOMAIN>` | `http://127.0.0.1:8002` | Interface Beszel |
| `t3.<STACK_DOMAIN>` | `http://127.0.0.1:8003` | Interface T3, MCP et configuration sur `/__setup` |

`127.0.0.1` désigne ici l'hôte où tournent Docker **et** `cloudflared`. Un connecteur dans un conteneur a son propre loopback : il ne peut pas utiliser ces destinations sans configuration réseau adaptée. Les MCP Docker et Dockhand restent sur le réseau Docker interne ; ils n'ont pas de route publique dans ce tableau.

## Coolify derrière le tunnel

Cloudflare Tunnel route directement les chemins vers les trois ports de Coolify, sans proxy Nginx supplémentaire. Placer les routes spécifiques `^/app/.*` et `^/terminal/ws$` avant la route Coolify sans chemin : la première règle correspondante doit gagner. Les chemins sont des expressions régulières ; `^/app/.*` couvre `/app/…` sans router `/apps/`. Cloudflare transmet le chemin sans le supprimer ni le réécrire. Vérifier le routage effectif et les WebSockets après configuration. Les trois ports sont liés uniquement à loopback sur l'hôte.

[Coolify recommande](https://coolify.io/docs/core/instance-management/reverb-migration) aussi une autre approche : son proxy géré sur le port 80, qui rassemble ces routes. Pour publier les applications créées dans Coolify, configurer le serveur et son proxy séparément, puis suivre son [guide Tunnel pour toutes les ressources](https://coolify.io/docs/integrations/networking/cloudflare/tunnels/all-resource). Vérifier l'accès SSH, les ports disponibles et les DNS existants avant de modifier les routes. Les politiques Access des applications dépendent de leurs utilisateurs et clients.

## Mise en place

1. Conserver une session SSH fonctionnelle pour le bootstrap et le dépannage. Lancer `sudo ./scripts/deploy-dockhand.sh` depuis le dépôt : Dockhand écoute sur le port local 8000.
2. Dans Cloudflare, choisir un tunnel existant connecté au même hôte ou créer un tunnel géré à distance, puis installer son connecteur sur cet hôte selon les instructions du tableau de bord. Vérifier qu'il est connecté avant d'ajouter les routes. Un tunnel déjà utilisé par un autre serveur ne donne pas automatiquement accès au loopback de ce serveur : éviter de connecter des machines aux origines différentes au même tunnel sans concevoir le routage.
3. Dans **Networking → Tunnels**, ajouter les routes Published application du tableau. Créer ou vérifier les enregistrements DNS associés, normalement des CNAME proxifiés vers le tunnel. Éviter d'écraser des DNS ou routes déjà utilisés.
4. Dans Cloudflare Zero Trust, créer les applications **Access self-hosted** et leurs règles *Allow* pour les identités autorisées avant de publier les routes. Protéger Dockhand, Coolify, Beszel et T3. Créer aussi une application Access plus spécifique pour `t3.<STACK_DOMAIN>/__setup*`, limitée aux administrateurs, et vérifier qu’elle couvre `/__setup` ainsi que ses sous-chemins ; appliquer une règle appropriée au reste de T3. Vérifier la priorité effective des applications selon la documentation Cloudflare et tester avec un utilisateur autorisé à T3 mais pas à Setup. Limiter Dockhand aux administrateurs. Vérifier l'ordre des règles et tester avec un compte non autorisé. Tunnel et DNS ne créent pas à eux seuls une authentification Access. Conserver aussi l'authentification native de chaque service.
5. Via `https://dockhand.<STACK_DOMAIN>`, créer l'administrateur puis une stack Git pointant vers `docker-compose.yml`. Saisir `STACK_DOMAIN`, les deux secrets MCP Dockhand et les autres variables nécessaires. Déployer puis configurer les services. Régler l'URL de l'instance Coolify dans son interface sur `https://coolify.<STACK_DOMAIN>` si nécessaire ; une variable d'environnement ne crée ni route Cloudflare ni configuration persistante dans son interface.
6. Vérifier les quatre noms publics après authentification, puis les WebSockets T3, Beszel et Coolify, les mises à jour en direct et le terminal Coolify. `PUSHER_HOST`, `PUSHER_PORT=443` et `TERMINAL_PORT=443` sont fournis à Coolify par Compose. Vérifier dans le navigateur que `/app/…` se connecte en `wss` sur 443 et que `/terminal/ws` fonctionne. Autoriser les WebSockets sur la zone. Une page de connexion Access renvoyée à un client WebSocket peut empêcher son fonctionnement : adapter l'authentification et tester chaque flux, sans désactiver aveuglément les protections.

Le TLS est terminé chez Cloudflare ; entre `cloudflared` et les ports loopback, ces origines utilisent HTTP. Les ports ne sont pas publiés sur l'interface réseau publique du serveur. Ne pas ouvrir 8000–8003, 6001 ou 6002 sur Internet.

## Clients non interactifs

Les règles Access prévues pour un navigateur peuvent bloquer les clients MCP, les clients mobiles T3 et les webhooks. Définir un accès machine ciblé selon les besoins : par exemple un **service token Access** pour un client capable d'envoyer `CF-Access-Client-Id` et `CF-Access-Client-Secret`, avec une règle Service Auth limitée à l'application concernée. Ne pas exposer ces secrets dans Git ou dans le prompt de l'agent. Si un client ne peut pas envoyer ces en-têtes, choisir une autre voie compatible, par exemple accès interne, WARP ou tunnel privé, en conservant l'authentification propre au service. Tester séparément les connexions navigateur, MCP et WebSocket ; une connexion navigateur autorisée ne prouve pas qu'un client natif fonctionne.

## Migration de T3 vers le port unifié

Après redéploiement, faire pointer `t3.<STACK_DOMAIN>` vers `http://127.0.0.1:8003` et protéger également `t3.<STACK_DOMAIN>/__setup*` dans Access. Tester `https://t3.<STACK_DOMAIN>/__setup` avec les comptes autorisés et refusés, puis retirer l’ancienne route et l’application `t3-setup.<STACK_DOMAIN>` si elles existent. Le port hôte 8004 n’est plus publié.

Le port unifié fait confiance aux en-têtes de proxy pour que Setup reconnaisse HTTPS et marque ses cookies comme sécurisés. Son port hôte reste sur loopback ; les conteneurs du réseau `microstack-control` peuvent toutefois joindre directement T3 et doivent être de confiance. Les ports internes 3773 et 3774 de l’image restent accessibles aux conteneurs de ce réseau.

## Migration des routes Coolify

Après redéploiement, créer les routes spécifiques Reverb et terminal du tableau avant la route générale vers 8001. Si le proxy Nginx de cette stack était déjà déployé, le retirer comme service orphelin dans Dockhand après la mise à jour : il ne doit plus occuper le port 8001. Conserver les anciennes routes jusqu'à vérification des nouvelles, puis retirer l'ancien nom `coolify-realtime.<STACK_DOMAIN>` s'il n'est plus utilisé. Tester l'interface, les mises à jour en direct et le terminal avec les règles Access ; prévoir une interruption pendant le changement.

## Modification du domaine ou récupération

Pour changer de domaine, préparer les DNS, certificats et applications Access du nouveau domaine, modifier `STACK_DOMAIN` dans Dockhand puis redéployer. Mettre à jour en parallèle les routes Tunnel et les URL enregistrées dans les interfaces, les clients OAuth et les MCP ; les anciennes URL peuvent rester dans les données persistantes. Vérifier le nouveau parcours avant de retirer l'ancien.

En cas de panne Cloudflare, les ports restent accessibles depuis l'hôte ou par le tunnel SSH du README. L'interface Coolify reste accessible ainsi, mais ses réglages publics Reverb et terminal pointent vers Cloudflare : le temps réel et le terminal ne sont pas garantis par le seul tunnel SSH. Un `502` indique notamment un connecteur ou une origine injoignable ; une page Access inattendue appelle une vérification des applications et politiques ; une interface chargée sans temps réel appelle une vérification des routes et WebSockets. Les services, identifiants et données persistent indépendamment du tunnel.

## Références

- [Cloudflare Tunnel : routage par chemin](https://developers.cloudflare.com/learning-paths/clientless-access/connect-private-applications/create-tunnel/)
- [Cloudflare Tunnel : démarrage et routes](https://developers.cloudflare.com/tunnel/get-started/)
- [Cloudflare Access : applications self-hosted](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted/)
- [Cloudflare Access : service tokens](https://developers.cloudflare.com/cloudflare-one/access-controls/service-credentials/service-tokens/)
- [Coolify : migration Reverb et routes Tunnel](https://coolify.io/docs/core/instance-management/reverb-migration)
