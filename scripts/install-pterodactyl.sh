#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

log() { printf '\n[%s] %s\n' "$(date -Is)" "$*"; }
fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || fail "Run as root."
[[ -n "$PANEL_DOMAIN" && -n "$WINGS_DOMAIN" && -n "$CONTACT_EMAIL" && -n "$ADMIN_EMAIL" && -n "$ADMIN_PASSWORD" ]] || fail "Required variables are missing."
[[ "$PANEL_DOMAIN" =~ ^([A-Za-z0-9-]+\.)+[A-Za-z]{2,}$ ]] || fail "Invalid Panel DNS name."
[[ "$WINGS_DOMAIN" =~ ^([A-Za-z0-9-]+\.)+[A-Za-z]{2,}$ ]] || fail "Invalid Wings DNS name."
[[ "$PANEL_DOMAIN" != "$WINGS_DOMAIN" ]] || fail "Panel and Wings need separate DNS names."
[[ "$CONTACT_EMAIL" == *@*.* && "$ADMIN_EMAIL" == *@*.* ]] || fail "Invalid email address."
[[ "$(printf '%s' "$ADMIN_PASSWORD" | wc -c)" -ge 12 ]] || fail "Admin password must contain at least 12 characters."

. /etc/os-release
[[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]] || fail "Fresh Ubuntu 24.04 only."
VIRT="$(systemd-detect-virt 2>/dev/null || true)"
[[ "$VIRT" != "lxc" && "$VIRT" != "openvz" ]] || fail "Wings requires working Docker support; use KVM or verify nested Docker support."
[[ ! -e /var/www/pterodactyl/.env ]] || fail "Panel already exists. Refusing to overwrite."
[[ ! -e /etc/pterodactyl/config.yml ]] || fail "Wings config already exists. Refusing to overwrite."

PANEL_VERSION="v1.15.2"
WINGS_VERSION="v1.13.5"
PANEL_DIR="/var/www/pterodactyl"
DB_PASSWORD="$(openssl rand -hex 32)"
HASHIDS_SALT="$(openssl rand -hex 32)"

log "Installing Panel dependencies."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release software-properties-common \
  nginx mariadb-server redis-server certbot python3-certbot-nginx tar unzip git cron openssl \
  php8.3 php8.3-cli php8.3-common php8.3-gd php8.3-mysql php8.3-mbstring \
  php8.3-bcmath php8.3-xml php8.3-fpm php8.3-curl php8.3-zip php8.3-intl php8.3-redis
systemctl enable --now mariadb redis-server php8.3-fpm nginx cron

log "Installing Composer 2 with checksum verification."
EXPECTED_CHECKSUM="$(curl -fsSL https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"
[[ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]] || fail "Composer installer checksum mismatch."
php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f /tmp/composer-setup.php

log "Installing Docker Engine."
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | CHANNEL=stable sh
fi
systemctl enable --now docker

log "Creating Panel database."
mariadb --protocol=socket <<SQL
CREATE DATABASE IF NOT EXISTS panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD';
ALTER USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL

log "Downloading Pterodactyl Panel $PANEL_VERSION."
install -d -m 0755 "$PANEL_DIR"
curl -fL --retry 3 "https://github.com/pterodactyl/panel/releases/download/$PANEL_VERSION/panel.tar.gz" -o /tmp/pterodactyl-panel.tar.gz
tar -xzf /tmp/pterodactyl-panel.tar.gz -C "$PANEL_DIR"
rm -f /tmp/pterodactyl-panel.tar.gz
cd "$PANEL_DIR"
cp .env.example .env
mkdir -p storage bootstrap/cache
chmod -R 755 storage bootstrap/cache

log "Writing Panel environment."
export PANEL_DOMAIN DB_PASSWORD HASHIDS_SALT CONTACT_EMAIL
python3 <<'PY'
import os
from pathlib import Path

env_file = Path("/var/www/pterodactyl/.env")
updates = {
    "APP_ENV": "production",
    "APP_DEBUG": "false",
    "APP_TIMEZONE": "Asia/Kolkata",
    "APP_URL": "https://" + os.environ["PANEL_DOMAIN"],
    "APP_LOCALE": "en",
    "APP_ENVIRONMENT_ONLY": "false",
    "LOG_CHANNEL": "daily",
    "DB_CONNECTION": "mysql",
    "DB_HOST": "127.0.0.1",
    "DB_PORT": "3306",
    "DB_DATABASE": "panel",
    "DB_USERNAME": "pterodactyl",
    "DB_PASSWORD": os.environ["DB_PASSWORD"],
    "REDIS_HOST": "127.0.0.1",
    "REDIS_PASSWORD": "null",
    "REDIS_PORT": "6379",
    "CACHE_DRIVER": "redis",
    "SESSION_DRIVER": "redis",
    "QUEUE_CONNECTION": "redis",
    "MAIL_MAILER": "log",
    "MAIL_FROM_ADDRESS": os.environ["CONTACT_EMAIL"],
    "MAIL_FROM_NAME": '"HavenSMP Panel"',
    "HASHIDS_SALT": os.environ["HASHIDS_SALT"],
}
lines = env_file.read_text().splitlines()
seen = set()
out = []
for line in lines:
    if "=" in line and not line.lstrip().startswith("#"):
        key = line.split("=", 1)[0]
        if key in updates:
            out.append(key + "=" + updates[key])
            seen.add(key)
            continue
    out.append(line)
for key, value in updates.items():
    if key not in seen:
        out.append(key + "=" + value)
env_file.write_text("\n".join(out) + "\n")
PY

log "Installing PHP dependencies and generating Panel APP_KEY."
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction
php artisan key:generate --force --no-interaction
php artisan config:clear

log "Migrating database and seeding the default Pterodactyl Nests and Eggs."
php artisan migrate --seed --force --no-interaction

log "Creating DeepuRana administrator."
php artisan p:user:make "$ADMIN_EMAIL" \
  --username=DeepuRana \
  --name-first=Deepu \
  --name-last=Rana \
  --admin=1 \
  --password="$ADMIN_PASSWORD" \
  --no-interaction
unset ADMIN_PASSWORD

log "Configuring Panel queue worker and scheduler."
cat >/etc/systemd/system/pteroq.service <<'UNIT'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now pteroq.service
( crontab -l 2>/dev/null | grep -v '/var/www/pterodactyl/artisan schedule:run' || true
  echo '* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1' ) | crontab -

log "Configuring NGINX."
cat >/etc/nginx/sites-available/haven-pterodactyl.conf <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $PANEL_DOMAIN;
    root $PANEL_DIR/public;
    index index.php;
    charset utf-8;
    client_max_body_size 100m;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
    }
    location ~ /\.ht { deny all; }
}
NGINX
ln -sfn /etc/nginx/sites-available/haven-pterodactyl.conf /etc/nginx/sites-enabled/haven-pterodactyl.conf
rm -f /etc/nginx/sites-enabled/default
chown -R www-data:www-data "$PANEL_DIR"
nginx -t
systemctl reload nginx

log "Obtaining Panel HTTPS certificate (Panel DNS must already point here)."
certbot --nginx --non-interactive --agree-tos --redirect --email "$CONTACT_EMAIL" -d "$PANEL_DOMAIN"

log "Obtaining a separate Wings hostname certificate."
install -d -m 0755 /var/www/letsencrypt/.well-known/acme-challenge
cat >/etc/nginx/sites-available/haven-wings-acme.conf <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $WINGS_DOMAIN;
    location ^~ /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
        default_type text/plain;
        try_files \$uri =404;
    }
    location / { return 404; }
}
NGINX
ln -sfn /etc/nginx/sites-available/haven-wings-acme.conf /etc/nginx/sites-enabled/haven-wings-acme.conf
nginx -t
systemctl reload nginx
certbot certonly --webroot --webroot-path /var/www/letsencrypt --non-interactive --agree-tos --email "$CONTACT_EMAIL" -d "$WINGS_DOMAIN"

log "Installing official Wings $WINGS_VERSION binary."
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) WINGS_ARCH="amd64" ;;
  aarch64|arm64) WINGS_ARCH="arm64" ;;
  *) fail "Unsupported CPU architecture: $ARCH" ;;
esac
install -d -m 0755 /etc/pterodactyl /var/lib/pterodactyl/volumes /var/lib/pterodactyl/backups /var/lib/pterodactyl/archives
curl -fL --retry 3 "https://github.com/pterodactyl/wings/releases/download/$WINGS_VERSION/wings_linux_$WINGS_ARCH" -o /usr/local/bin/wings
chmod 0755 /usr/local/bin/wings

cat >/etc/systemd/system/wings.service <<'UNIT'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload

log "Finalizing Panel services."
chown -R www-data:www-data "$PANEL_DIR"
systemctl restart php8.3-fpm nginx redis-server mariadb pteroq
php artisan config:cache

PUBLIC_IP="$(curl -4 -fsSL --max-time 10 https://api.ipify.org 2>/dev/null || true)"
if [[ -z "$PUBLIC_IP" ]]; then PUBLIC_IP="check with your VPS provider"; fi
cat >/root/haven-pterodactyl-install-info.txt <<INFO
HavenSMP Pterodactyl installation
Panel URL: https://$PANEL_DOMAIN
Wings FQDN: $WINGS_DOMAIN
Panel version: $PANEL_VERSION
Wings binary version: $WINGS_VERSION
Default Eggs: seeded via php artisan migrate --seed
Administrator: DeepuRana ($ADMIN_EMAIL)
Wings service: installed; awaiting node configuration.
Keep /var/www/pterodactyl/.env private and back it up securely.
INFO
chmod 0600 /root/haven-pterodactyl-install-info.txt

log "Panel installation completed."
printf '\nPanel URL: https://%s\n' "$PANEL_DOMAIN"
printf 'Wings hostname: %s\n' "$WINGS_DOMAIN"
printf 'Administrator: DeepuRana (%s)\n' "$ADMIN_EMAIL"
printf 'Detected public IPv4: %s\n' "$PUBLIC_IP"
printf '\nNEXT: Create a Panel node with FQDN %s, SSL enabled, daemon port 8080 and SFTP port 2022. Add allocations. Copy the generated node config to GitHub secret HAVEN_WINGS_CONFIG, then run Configure HavenSMP Wings.\n' "$WINGS_DOMAIN"
printf 'Open TCP 80/443, 8080, 2022 and the game allocation ports in both VPS and provider firewalls. Do not expose MariaDB or Redis publicly.\n'
printf 'Back up /var/www/pterodactyl/.env securely. Losing APP_KEY makes encrypted Panel data unrecoverable.\n'
