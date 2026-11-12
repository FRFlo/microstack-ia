# MCP disponibles et configuration

Un MCP est un serveur exposant des outils à un agent. Un socket Docker, une interface web ou un service ne sont pas en eux-mêmes des serveurs MCP.

| Serveur | Disponibilité | Mise en service |
| --- | --- | --- |
| T3 Code `/mcp` | Serveur proposé par T3 Code aux agents externes | Dans T3, Settings → Environments, copier l'URL et suivre l'autorisation OAuth. Pour un agent externe, utiliser un tunnel local ou une connexion HTTPS/T3 Connect adaptée. |
| Playwright | Fourni par l'image T3 `latest` | Après installation d'un agent, ouvrir le terminal du conteneur dans Dockhand et exécuter `t3-browser-mcp`, puis démarrer une nouvelle session d'agent. |
| Chrome DevTools | Fourni par l'image T3 `latest` | Alternative : `t3-browser-mcp --server chrome-devtools --harness claude`, puis nouvelle session. L'association avec Chromium est moins éprouvée selon la documentation de l'image. |

L'installation des agents et l'enregistrement des serveurs navigateur sont des étapes distinctes. Vérifiez dans chaque agent les outils effectivement exposés ; leur présence dans l'image ne signifie pas qu'ils sont enregistrés ou connectés.

## Ajouter un MCP

La page Setup → MCP servers de T3 permet de déclarer des serveurs locaux ou HTTP Streamable et de les appliquer aux agents choisis. Leur installation, leur lancement et leur authentification restent à organiser selon chaque serveur. Une autorisation OAuth peut être nécessaire pour chaque agent. Ne placez pas de secrets dans les commandes enregistrées ni dans le dépôt ; utilisez les mécanismes de secrets du service concerné.

Aucun serveur MCP Docker, Dockhand, Coolify, Beszel, PostgreSQL ou Redis n'est déclaré par ce dépôt. Vous pouvez en ajouter un après avoir choisi sa source et ses permissions. Les interfaces web restent accessibles aux outils de navigateur sur le réseau partagé : `http://dockhand:3000`, `http://coolify:8080` et `http://beszel:8090`. Le navigateur de l'agent possède sa propre session : votre connexion dans votre navigateur personnel ne l'authentifie pas automatiquement.

T3 dispose du socket Docker de l'hôte, sous réserve des permissions du socket. L'image ne garantit pas la présence de la commande `docker` ; depuis son terminal, le diagnostic `curl --unix-socket /var/run/docker.sock http://localhost/_ping` interroge directement l'API. L'accès à cette API donne des pouvoirs étendus sur l'hôte.

## Documentation amont

- [Configuration MCP de l'image T3](https://github.com/dizys/t3code-docker/blob/main/docs/mcp-servers.md)
- [MCP navigateur de l'image T3](https://github.com/dizys/t3code-docker/blob/main/docs/agent-browser.md)
- [Serveur MCP de T3 Code pour agents externes](https://github.com/pingdotgg/t3code/blob/main/docs/user/outside-agents.md)

Les versions récentes de T3 proposent aussi un navigateur intégré dans le panneau Browser ; il est distinct des serveurs MCP ci-dessus et peut nécessiter une configuration du sandbox navigateur sur l’hôte. Voir la [documentation navigateur amont](https://github.com/dizys/t3code-docker/blob/main/docs/agent-browser.md).
