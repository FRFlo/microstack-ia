#!/usr/bin/env bash
# Bootstrap Dockhand sur l'hôte ; la stack applicative sera ensuite déployée depuis Git dans Dockhand.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
compose_file="$script_dir/../docker-compose.dockhand.yml"

if ! command -v docker >/dev/null 2>&1; then
  echo 'Docker Engine est requis sur le serveur.' >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo 'Le plugin Docker Compose est requis.' >&2
  exit 1
fi
if [[ ! -S /var/run/docker.sock ]]; then
  echo 'Le socket Docker /var/run/docker.sock est introuvable.' >&2
  exit 1
fi

docker compose -f "$compose_file" up -d
port="${DOCKHAND_PORT:-3000}"
printf 'Dockhand est démarré. Depuis votre poste, ouvrez un tunnel :\n'
printf '  ssh -L %s:127.0.0.1:%s utilisateur@serveur\n' "$port" "$port"
printf 'Puis ouvrez http://localhost:%s et ajoutez la stack depuis son dépôt Git.\n' "$port"
