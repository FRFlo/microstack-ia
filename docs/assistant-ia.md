# Utiliser un assistant IA

## Préparer l'agent

Après le déploiement décrit dans le [README](../README.md), ouvrez Setup sur le port 8004, installez l'agent voulu et connectez son fournisseur. Dans T3 Code, ouvrez ou clonez ce dépôt dans `/workspace` : la copie Git utilisée par Dockhand est distincte de l'espace de travail T3. Ainsi l'agent pourra lire [AGENTS.md](../AGENTS.md), les fichiers Compose et les guides.

Enregistrez les MCP souhaités selon [l'inventaire](mcp.md), puis démarrez une nouvelle session de l'agent. Les connexions aux comptes et les éventuelles autorisations OAuth doivent être effectuées par leur titulaire. Le navigateur MCP n'hérite pas de votre session personnelle.

## Prompt initial

> Lis `AGENTS.md`, `README.md`, `docs/exploitation.md` et `docs/mcp.md`. Aide-moi à terminer l'installation et à exploiter cette stack. Commence par examiner les fichiers et inventorier les outils MCP réellement disponibles, les services et leurs états, sans afficher de secrets. Vérifie si tu peux accéder à l'API Docker et aux interfaces nécessaires. Distingue ce qui est déjà opérationnel, ce que tu peux faire et ce qui nécessite mon intervention ou une connexion. Guide-moi pour initialiser Coolify et Beszel, puis propose les prochaines étapes adaptées à mon objectif. Préserve les volumes et sauvegardes existants et signale toute migration nécessaire. Ne suppose pas qu'une action ou un déploiement a réussi sans résultat observable.

Précisez ensuite votre objectif : applications à déployer, domaines, stockage, sauvegardes ou supervision. L'agent doit demander les informations et accès manquants sans vous demander de coller vos secrets dans la conversation.

## Cycle Git

Les modifications locales effectuées dans T3 ne modifient pas automatiquement la copie Git de Dockhand. Publiez les changements sur la branche suivie par la stack, puis synchronisez ou redéployez dans Dockhand selon la configuration choisie. Vérifiez ensuite l'état réel des services. La synchronisation automatique n'est active que si vous l'avez configurée dans Dockhand.
