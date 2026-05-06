#!/bin/bash
set -euo pipefail

# TLS / domain (no https:// prefix)
DOMAIN_NAME="test.asyncawaits.com" # Edit these before running
EMAIL="mardiyaabhishek@gmail.com" # Edit these before running

# Where to clone or update the app on the server
REPO_URL="git@github.com:abhishekmardiya/nextjs-self-host.git"  # Edit these before running
APP_DIR="${HOME}/nextjs-self-host"

SWAP_SIZE="1G"

if [[ -z "${EMAIL}" || "${EMAIL}" == "your-email@example.com" ]]; then
  echo "Set EMAIL at the top of deploy.sh to a real address for Let's Encrypt."
  exit 1
fi

# Update package list and upgrade existing packages
sudo apt update && sudo apt upgrade -y

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

# Clone or update repo
if [[ -d "${APP_DIR}" ]]; then
  echo "Directory ${APP_DIR} already exists. Pulling latest changes..."
  git -C "${APP_DIR}" pull
else
  echo "Cloning repository from ${REPO_URL}..."
  git clone "${REPO_URL}" "${APP_DIR}"
fi

# ReqRes vars: compose.yml uses env_file: .env — one source only (no Docker-only copy).
ensure_reqres_dotenv() {
  local env_path="${APP_DIR}/.env"

  if [[ -f "${env_path}" ]] && grep -qE '^REQ_RES_API_KEY=.+' "${env_path}" &&
    grep -qE '^REQ_RES_PROJECT_ID=.+' "${env_path}"; then
    echo "Using existing ${env_path} (picked up by Docker Compose)."
    return
  fi

  if [[ -n "${REQ_RES_API_KEY:-}" && -n "${REQ_RES_PROJECT_ID:-}" ]]; then
    printf '%s\n' "REQ_RES_API_KEY=${REQ_RES_API_KEY}" "REQ_RES_PROJECT_ID=${REQ_RES_PROJECT_ID}" > "${env_path}"
    echo "Wrote ${env_path} from REQ_RES_* in the environment."
    return
  fi

  echo "Compose needs REQ_RES_API_KEY and REQ_RES_PROJECT_ID in ${env_path}.
Create that file on the server (see env.sample), or export both variables for a one-time write."
  exit 1
}

ensure_reqres_dotenv

# Nginx
sudo apt install -y nginx

sudo rm -f /etc/nginx/sites-available/nextjs-self-host
sudo rm -f /etc/nginx/sites-enabled/nextjs-self-host

sudo systemctl stop nginx

sudo apt install -y certbot wget
sudo certbot certonly --standalone -d "${DOMAIN_NAME}" --non-interactive --agree-tos -m "${EMAIL}"

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
HTTPS: https://${DOMAIN_NAME}
App runs in Docker on port 3000; Nginx terminates TLS and proxies to it.

ReqRes credentials live in ${APP_DIR}/.env (read by Compose via env_file)."
