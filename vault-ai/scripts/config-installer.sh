#!/bin/bash

# =============================================================================
# VAULT AI - CONFIGURATION INSTALLER
# =============================================================================

# Source the logger and common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
VAULT_AI_ROOT="$(dirname "$SCRIPT_DIR")"

if ! source "$SCRIPT_DIR/logger.sh"; then
  echo "[ERROR] Failed to source logger.sh" >&2
  exit 1
fi
if ! source "$SCRIPT_DIR/common.sh"; then
  log_error "Failed to source common.sh"
  exit 1
fi

# Print the main header
{

  # Parse test flag
  TEST_DEPLOY=0
  for arg in "$@"; do
    case "$arg" in
      --test)
        TEST_DEPLOY=1
        ;;
    esac
  done

  # Print test mode info if enabled
  if [ "$TEST_DEPLOY" = "1" ]; then
      log_test_mode
  fi
} >&2

# Set default values
VAULT_AI_DIR="/opt/vault-ai"
VAULT_USER="vault-ai"
VAULT_GROUP="vault-ai"
REPO_URL="git@github.com:vektorsystems/vault-ai.git"
SERVICE_NAME="vault-ai"
NGINX_SITE="vault-ai"
NODE_VERSION="22.x"
PYTHON_VERSION="3.11"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="vault-ai"
DB_USER="vault-ai"
DB_PASSWORD="vault-ai"
WEBUI_NAME="Vault AI"
PORT="8080"
WEBUI_HOST="0.0.0.0"
WEBUI_SECRET_KEY=$([ "$TEST_DEPLOY" = "1" ] && echo "==test-secret-key==" || openssl rand -hex 32)

# Export variables for other scripts
export VAULT_AI_DIR VAULT_USER VAULT_GROUP REPO_URL SERVICE_NAME NGINX_SITE NODE_VERSION PYTHON_VERSION
export PORT DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD WEBUI_NAME WEBUI_HOST WEBUI_SECRET_KEY
export TEST_DEPLOY

# Print Configuration to stderr
{
  log_task "Configuration Values"

  log_clean "--------------------------------------------------"
  log_clean "## System/Deployment Variables:"
  log_clean ""
  log_clean "VAULT_AI_DIR=${VAULT_AI_DIR}"
  log_clean "VAULT_USER=${VAULT_USER}"
  log_clean "VAULT_GROUP=${VAULT_GROUP}"
  log_clean "REPO_URL=${REPO_URL}"
  log_clean "SERVICE_NAME=${SERVICE_NAME}"
  log_clean "NGINX_SITE=${NGINX_SITE}"
  log_clean "NODE_VERSION=${NODE_VERSION}"
  log_clean "PYTHON_VERSION=${PYTHON_VERSION}"
  log_clean ""
  log_clean "## Open WebUI Application Variables:"
  log_clean ""
  log_clean "PORT=${PORT}"
  log_clean "DB_HOST=${DB_HOST}"
  log_clean "DB_PORT=${DB_PORT}"
  log_clean "DB_NAME=${DB_NAME}"
  log_clean "DB_USER=${DB_USER}"
  log_clean "DB_PASSWORD=${DB_PASSWORD}"
  log_clean "WEBUI_NAME=${WEBUI_NAME}"
  log_clean "WEBUI_HOST=${WEBUI_HOST}"
  log_clean "--------------------------------------------------"

  log_success "Configuration completed successfully"
} >&2

# Print exports to stdout for sourcing
cat << EOF
export VAULT_AI_DIR="$VAULT_AI_DIR"
export VAULT_USER="$VAULT_USER"
export VAULT_GROUP="$VAULT_GROUP"
export REPO_URL="$REPO_URL"
export SERVICE_NAME="$SERVICE_NAME"
export NGINX_SITE="$NGINX_SITE"
export NODE_VERSION="$NODE_VERSION"
export PYTHON_VERSION="$PYTHON_VERSION"
export DB_HOST="$DB_HOST"
export DB_PORT="$DB_PORT"
export DB_NAME="$DB_NAME"
export DB_USER="$DB_USER"
export DB_PASSWORD="$DB_PASSWORD"
export WEBUI_NAME="$WEBUI_NAME"
export PORT="$PORT"
export WEBUI_HOST="$WEBUI_HOST"
export WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY"
export TEST_DEPLOY="$TEST_DEPLOY"
EOF