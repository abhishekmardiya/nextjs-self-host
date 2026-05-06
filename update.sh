#!/bin/bash
set -euo pipefail

# Match deploy.sh — edit if your server layout differs
REPO_URL="git@github.com:abhishekmardiya/nextjs-self-host.git"
APP_DIR="${HOME}/nextjs-self-host"
COMPOSE_FILE="compose.yml"

if [[ -d "${APP_DIR}" ]]; then
  echo "Pulling latest changes..."
  git -C "${APP_DIR}" pull --ff-only
else
  echo "Cloning repository from ${REPO_URL}..."
  git clone "${REPO_URL}" "${APP_DIR}"
fi

cd "${APP_DIR}"

if [[ ! -f ".env" ]]; then
  echo "Missing ${APP_DIR}/.env (Compose env_file). Create it from env.sample before updating."
  exit 1
fi

echo "Rebuilding and restarting containers..."
sudo docker compose -f "${COMPOSE_FILE}" down
sudo docker compose -f "${COMPOSE_FILE}" up --build -d

if ! sudo docker compose -f "${COMPOSE_FILE}" ps | grep -q 'Up'; then
  echo "Containers did not start. Check: sudo docker compose -f ${COMPOSE_FILE} logs"
  exit 1
fi

echo "Update complete. Next.js app is running with the latest changes."
