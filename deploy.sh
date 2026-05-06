#!/bin/bash
set -euo pipefail

# Optional file before first clone: REPO_URL, APP_DIR (defaults below if unset). Same keys as ${APP_DIR}/.env.
# Override path: export DEPLOY_DOTENV=/path/to/file
BOOTSTRAP_ENV="${DEPLOY_DOTENV:-${HOME}/nextjs-self-host.env}"

if [[ -f "${BOOTSTRAP_ENV}" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${BOOTSTRAP_ENV}"
  set +a
fi

# Resolved install path (bootstrap / export / default)
INSTALL_ROOT="${APP_DIR:-${HOME}/nextjs-self-host}"

SWAP_SIZE="1G"

sudo apt update
sudo apt install -y git

# Clone or update repo — first clone needs REPO_URL (bootstrap file or export)
if [[ -d "${INSTALL_ROOT}" ]]; then
  echo "Directory ${INSTALL_ROOT} already exists. Pulling latest changes..."
  git -C "${INSTALL_ROOT}" pull
else
  if [[ -z "${REPO_URL:-}" ]]; then
    echo "First clone needs REPO_URL — set it in ${BOOTSTRAP_ENV} (see env.sample) or export REPO_URL before deploy.sh."
    exit 1
  fi
  echo "Cloning repository from ${REPO_URL}..."
  git clone "${REPO_URL}" "${INSTALL_ROOT}"
fi

if [[ ! -f "${INSTALL_ROOT}/.env" ]]; then
  if [[ -f "${BOOTSTRAP_ENV}" ]]; then
    echo "Copying ${BOOTSTRAP_ENV} to ${INSTALL_ROOT}/.env"
    cp "${BOOTSTRAP_ENV}" "${INSTALL_ROOT}/.env"
  else
    echo "Missing ${INSTALL_ROOT}/.env — add env.sample there or create ${BOOTSTRAP_ENV} and re-run."
    exit 1
  fi
fi

set -a
# shellcheck disable=SC1091
source "${INSTALL_ROOT}/.env"
set +a

# Canonical app directory on disk (if APP_DIR appears in .env it must match INSTALL_ROOT)
if [[ -n "${APP_DIR:-}" ]] && [[ "${APP_DIR}" != "${INSTALL_ROOT}" ]]; then
  echo "APP_DIR in .env (${APP_DIR}) must match the install directory (${INSTALL_ROOT})."
  exit 1
fi
APP_DIR="${INSTALL_ROOT}"

if [[ -z "${DOMAIN_NAME:-}" ]]; then
  echo "Set DOMAIN_NAME in ${APP_DIR}/.env (see env.sample)."
  exit 1
fi

if [[ -z "${LETS_ENCRYPT_EMAIL:-}" ]]; then
  echo "Set LETS_ENCRYPT_EMAIL in ${APP_DIR}/.env for Certbot / Let's Encrypt (see env.sample)."
  exit 1
fi

# Update package list and upgrade existing packages
sudo apt upgrade -y

# Add swap (helps small VPS during builds)
echo "Adding swap space..."
if [[ ! -f /swapfile ]]; then
  sudo fallocate -l "${SWAP_SIZE}" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  if ! grep -q '/swapfile' /etc/fstab; then
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  fi
fi

# Docker Engine + Compose plugin (Ubuntu)
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

# Nginx
sudo apt install -y nginx

sudo rm -f /etc/nginx/sites-available/nextjs-self-host
sudo rm -f /etc/nginx/sites-enabled/nextjs-self-host

sudo systemctl stop nginx

sudo apt install -y certbot wget
sudo certbot certonly --standalone -d "${DOMAIN_NAME}" --non-interactive --agree-tos -m "${LETS_ENCRYPT_EMAIL}"

if [[ ! -f /etc/letsencrypt/options-ssl-nginx.conf ]]; then
  sudo wget -q \
    https://raw.githubusercontent.com/certbot/certbot/main/certbot-nginx/src/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf \
    -P /etc/letsencrypt/
fi

if [[ ! -f /etc/letsencrypt/ssl-dhparams.pem ]]; then
  sudo openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
fi

sudo tee /etc/nginx/sites-available/nextjs-self-host > /dev/null <<EOL
limit_req_zone \$binary_remote_addr zone=next_limit:10m rate=10r/s;

server {
    listen 80;
    server_name ${DOMAIN_NAME};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${DOMAIN_NAME};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    limit_req zone=next_limit burst=20 nodelay;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_buffering off;
        proxy_set_header X-Accel-Buffering no;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/nextjs-self-host /etc/nginx/sites-enabled/nextjs-self-host
sudo systemctl restart nginx

cd "${APP_DIR}"
sudo docker compose -f compose.yml up --build -d

if ! sudo docker compose -f compose.yml ps | grep -q 'Up'; then
  echo "Docker Compose did not report Up containers. Check: sudo docker compose -f compose.yml logs"
  exit 1
fi

( crontab -l 2>/dev/null; echo "0 */12 * * * certbot renew --quiet && systemctl reload nginx" ) | crontab -

echo "Deployment complete.
HTTPS: https://${DOMAIN_NAME}"
