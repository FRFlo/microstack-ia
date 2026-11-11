#!/usr/bin/env bash
# Initialise les secrets une seule fois ; ne modifie jamais une installation existante.
set -euo pipefail
if [[ ${EUID} -ne 0 ]]; then
  echo 'Exécutez ce script avec sudo.' >&2
  exit 1
fi
command -v openssl >/dev/null || { echo 'openssl est requis.' >&2; exit 1; }
config=/data/coolify/source/.env
if [[ -e "$config" ]]; then
  echo "$config existe déjà : aucun secret modifié."
  exit 0
fi
if [[ -d /data/coolify ]] && [[ -n "$(ls -A /data/coolify)" ]]; then
  echo '/data/coolify contient déjà des données : installation annulée.' >&2
  exit 1
fi
umask 077
for dir in source ssh ssh/keys ssh/mux images applications databases services backups proxy proxy/dynamic sentinel; do
  install -d -m 700 -o 9999 -g 0 "/data/coolify/$dir"
done
# Valeurs hexadécimales sans caractères spéciaux pour les fichiers .env/Compose.
{
  printf 'APP_ID=%s\n' "$(openssl rand -hex 16)"
  printf 'APP_NAME=Coolify\n'
  printf 'APP_KEY=base64:%s\n' "$(openssl rand -base64 32)"
  printf 'DB_USERNAME=coolify\nDB_DATABASE=coolify\n'
  printf 'DB_PASSWORD=%s\n' "$(openssl rand -hex 32)"
  printf 'REDIS_PASSWORD=%s\n' "$(openssl rand -hex 32)"
  printf 'PUSHER_APP_ID=%s\n' "$(openssl rand -hex 32)"
  printf 'PUSHER_APP_KEY=%s\n' "$(openssl rand -hex 32)"
  printf 'PUSHER_APP_SECRET=%s\n' "$(openssl rand -hex 32)"
  printf 'AUTOUPDATE=false\nREGISTRY_URL=docker.io\n'
  printf 'COOLIFY_VERSION=4.7.5\n'
  printf '# Référence documentaire ; configurer aussi les domaines dans Coolify.\nBASE_DOMAIN=example.com\n'
} > "$config"
chown 9999:0 "$config"
chmod 600 "$config"
echo "Secrets créés dans $config. Sauvegardez ce fichier en lieu sûr."
