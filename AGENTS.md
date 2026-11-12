# Consignes pour les agents

Ce dépôt prépare une stack auto-hébergée gérée depuis Dockhand. Lire le README et les guides `docs/assistant-ia.md`, `docs/mcp.md` et `docs/exploitation.md` avant une intervention.

## Repères

- `scripts/deploy-dockhand.sh` initialise les dossiers, les secrets Coolify, la configuration locale T3, le réseau partagé et Dockhand.
- `docker-compose.dockhand.yml` décrit le bootstrap Dockhand ; `docker-compose.yml` décrit la stack Git Coolify, PostgreSQL, Redis, T3 et Beszel.
- Dockhand, Coolify, Beszel et T3 sont accessibles sur les ports locaux 8000 à 8004 ; voir le guide d'exploitation pour leur rôle et le réseau interne.
- Le workspace T3 et la copie du dépôt utilisée par Dockhand sont distincts. Une modification de code ne déploie pas automatiquement la stack.

## Méthode

1. Examiner la configuration et l'état réel avant de modifier ou redéployer. Identifier les outils, les serveurs MCP et les permissions réellement disponibles.
2. Ne jamais afficher ni enregistrer dans le dépôt les secrets, jetons ou contenus de fichiers d'environnement. Guider l'utilisateur vers les interfaces appropriées pour les saisir.
3. Préserver les volumes et données ; lire les consignes de migration avant toute recréation affectant les montages ou toute mise à jour majeure de PostgreSQL.
4. Utiliser les accès effectivement accordés ; ne pas inventer de serveur MCP, de session authentifiée ou de résultat de déploiement. Expliquer les actions et connexions nécessitant l'utilisateur.
5. Garder les guides, fichiers Compose et script cohérents. Rapporter les vérifications réalisées et leurs limites.
