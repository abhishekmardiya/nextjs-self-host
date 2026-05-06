#!/bin/bash
set -euo pipefail

COMPOSE_FILE="compose.yml"
DEFAULT_ROOT="${HOME}/nextjs-self-host"

BOOTSTRAP_ENV="${DEPLOY_DOTENV:-${HOME}/nextjs-self-host.env}"
if [[ -f "${BOOTSTRAP_ENV}" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${BOOTSTRAP_ENV}"
  set +a
fi

INSTALL_ROOT="${APP_DIR:-${DEFAULT_ROOT}}"

if [[ -f "${INSTALL_ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${INSTALL_ROOT}/.env"
  set +a
fi

APP_DIR="${APP_DIR:-${INSTALL_ROOT}}"
if [[ -n "${APP_DIR:-}" ]] && [[ "${APP_DIR}" != "${INSTALL_ROOT}" ]]; then
  echo "APP_DIR in .env (${APP_DIR}) must match install root (${INSTALL_ROOT})."
  exit 1
fi
APP_DIR="${INSTALL_ROOT}"

if [[ -z "${REPO_URL:-}" ]]; then
  echo "Set REPO_URL in ${APP_DIR}/.env or in ${BOOTSTRAP_ENV}."
  exit 1
fi

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
