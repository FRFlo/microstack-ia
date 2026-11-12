#!/usr/bin/env bash
# Bootstrap Dockhand sur l'hôte ; la stack applicative sera ensuite déployée depuis Git dans Dockhand.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
compose_file="$script_dir/../docker-compose.dockhand.yml"
coolify_env=/data/coolify/source/.env
t3code_env=/data/coolify/source/t3code.env

if [[ ${EUID} -ne 0 ]]; then
  echo 'Exécutez ce script avec sudo.' >&2
  exit 1
fi
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

command -v openssl >/dev/null 2>&1 || { echo 'openssl est requis.' >&2; exit 1; }
for dir in source ssh ssh/keys ssh/mux images applications databases services backups proxy proxy/dynamic webhooks-during-maintenance; do
  install -d -m 700 -o 9999 -g 0 "/data/coolify/$dir"
done
umask 077
if [[ ! -e "$coolify_env" ]]; then
  temp_env="$(mktemp /data/coolify/source/.coolify-env.XXXXXX)"
  trap 'rm -f -- "$temp_env"' EXIT
  app_id="$(openssl rand -hex 16)"
  app_key="$(openssl rand -base64 32)"
  db_password="$(openssl rand -hex 32)"
  redis_password="$(openssl rand -hex 32)"
  pusher_id="$(openssl rand -hex 32)"
  pusher_key="$(openssl rand -hex 32)"
  pusher_secret="$(openssl rand -hex 32)"
  {
    printf 'APP_ID=%s\n' "$app_id"
    printf 'APP_NAME=Coolify\n'
    printf 'APP_KEY=base64:%s\n' "$app_key"
    printf 'DB_USERNAME=coolify\nDB_DATABASE=coolify\nDB_HOST=postgres\nDB_PORT=5432\nDB_CONNECTION=pgsql\n'
    printf 'DB_PASSWORD=%s\n' "$db_password"
    printf 'REDIS_HOST=redis\nREDIS_PASSWORD=%s\nQUEUE_CONNECTION=redis\n' "$redis_password"
    printf 'PUSHER_APP_ID=%s\n' "$pusher_id"
    printf 'PUSHER_APP_KEY=%s\n' "$pusher_key"
    printf 'PUSHER_APP_SECRET=%s\n' "$pusher_secret"
    printf 'AUTOUPDATE=false\nREGISTRY_URL=docker.io\n'
  } > "$temp_env"
  chown 9999:0 "$temp_env"
  chmod 600 "$temp_env"
  ln "$temp_env" "$coolify_env"
  rm -f -- "$temp_env"
  trap - EXIT
  echo "Secrets Coolify créés dans $coolify_env. Sauvegardez ce fichier hors du serveur."
else
  echo "$coolify_env existe déjà : secrets Coolify conservés."
fi

socket_gid="$(stat -c '%g' /var/run/docker.sock)"
temp_env="$(mktemp /data/coolify/source/.t3code-env.XXXXXX)"
trap 'rm -f -- "$temp_env"' EXIT
printf 'PUID=1000\nPGID=%s\n' "$socket_gid" > "$temp_env"
chown 9999:0 "$temp_env"
chmod 600 "$temp_env"
mv -f -- "$temp_env" "$t3code_env"
trap - EXIT

if ! docker network inspect microstack-control >/dev/null 2>&1; then
  docker network create microstack-control >/dev/null
fi

docker compose -f "$compose_file" up -d
printf 'Dockhand est démarré. Depuis votre poste, ouvrez un tunnel :\n'
printf '  ssh -L 8000:127.0.0.1:8000 utilisateur@serveur\n'
printf 'Puis ouvrez http://localhost:8000 et ajoutez la stack depuis son dépôt Git.\n'
