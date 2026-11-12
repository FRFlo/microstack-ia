# Configuration MCP pour les agents

À l'ouverture de ce projet, configure les serveurs MCP utiles dans ta propre configuration d'agent. Conserve les autres serveurs déjà présents et utilise les outils MCP disponibles pour accomplir la tâche demandée.

## Procédure

1. Identifie ton agent, son fichier ou sa commande de configuration MCP, et les serveurs déjà déclarés. Si tu utilises T3, tu peux aussi gérer ces déclarations dans **Setup → MCP servers**, puis les appliquer à l'agent concerné.
2. Identifie les serveurs nécessaires à la tâche et vérifie leur adresse, leur transport et leur méthode d'authentification dans leur documentation ou leur configuration effective.
3. Ajoute chaque serveur à ta propre configuration, sans écraser les entrées existantes. Utilise les noms et adresses accessibles depuis ton environnement d'exécution.
4. Effectue l'authentification requise par le serveur. Utilise les mécanismes de secrets de l'agent ou du service ; ne place aucun jeton dans le dépôt, une commande enregistrée ou la conversation.
5. Recharge la configuration ou démarre une nouvelle session si ton agent l'exige, puis vérifie les outils effectivement exposés. Signale les étapes qui nécessitent une connexion ou une autorisation de l'utilisateur.

Par exemple, si Coolify expose effectivement un serveur MCP HTTP sur `http://coolify:8080/mcp`, configure cette URL comme serveur HTTP dans l'agent exécuté sur le réseau partagé. Le chemin `/mcp` est ici un exemple à vérifier : l'adresse de l'interface Coolify ne garantit pas qu'un serveur MCP y soit actif.

Depuis T3, les interfaces de la stack sont accessibles aux adresses `http://dockhand:3000`, `http://coolify:8080` et `http://beszel:8090`. Ces adresses désignent des interfaces web ; pour chacune, vérifie l'existence et l'URL du MCP avant de l'ajouter. Depuis un agent extérieur au réseau Docker, utilise une adresse accessible depuis cet agent.

## Serveurs navigateur et T3 Code

L'image T3 `latest` fournit Playwright et Chrome DevTools. Après l'installation des agents, exécute `t3-browser-mcp` dans le terminal du conteneur pour enregistrer Playwright auprès des agents pris en charge. Pour Chrome DevTools avec Claude, utilise `t3-browser-mcp --server chrome-devtools --harness claude`. Démarre ensuite une nouvelle session. Le navigateur intégré à T3 est distinct de ces MCP et ne partage pas automatiquement la session du navigateur personnel de l'utilisateur.

Pour connecter un agent externe au MCP de T3 Code, récupère l'URL dans **Settings → Environments**, configure-la dans l'agent et suis la procédure OAuth. L'agent externe doit pouvoir joindre T3 par une connexion adaptée, par exemple un tunnel ou HTTPS/T3 Connect.

L'accès au socket Docker dans T3 permet aussi d'interroger l'API Docker, mais ne constitue pas un MCP. La commande `curl --unix-socket /var/run/docker.sock http://localhost/_ping` permet d'en vérifier l'accès ; la présence de la commande `docker` dans l'image n'est pas garantie.

## Références

- [Configuration MCP de l'image T3](https://github.com/dizys/t3code-docker/blob/main/docs/mcp-servers.md)
- [MCP navigateur de l'image T3](https://github.com/dizys/t3code-docker/blob/main/docs/agent-browser.md)
- [Serveur MCP de T3 Code pour agents externes](https://github.com/pingdotgg/t3code/blob/main/docs/user/outside-agents.md)
