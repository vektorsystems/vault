#!/bin/bash

# =============================================================================
# VAULT AI - DEPLOY CONFIG INSTALLER
# =============================================================================

# Source the logger and common scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
if ! source "$SCRIPT_DIR/logger.sh"; then
  echo "[ERROR] Failed to source logger.sh" >&2
  exit 1
fi
if ! source "$SCRIPT_DIR/common.sh"; then
  log_error "Failed to source common.sh"
  exit 1
fi

# Print the main header
log_header "VAULT AI - DEPLOY CONFIG INSTALLER"

# Parse --test flag
for arg in "$@"; do
  if [[ "$arg" == "--test" ]]; then
    export TEST_DEPLOY=1
  fi
done

# Print test mode info if enabled
if [ "$TEST_DEPLOY" = "1" ]; then
    log_test_mode
fi

# System Configuration
log_task "Configuring system settings"

# Generate default values
DEFAULT_INSTANCE_ID=$(date +%s)
read -p "Enter INSTANCE_ID [${DEFAULT_INSTANCE_ID}]: " INSTANCE_ID
INSTANCE_ID=${INSTANCE_ID:-$DEFAULT_INSTANCE_ID}

DEFAULT_VAULT_DIR="/opt/vault-ai-${INSTANCE_ID}"
read -p "Enter VAULT_DIR [${DEFAULT_VAULT_DIR}]: " VAULT_DIR
VAULT_DIR=${VAULT_DIR:-$DEFAULT_VAULT_DIR}

VAULT_USER="vault-ai"
VAULT_GROUP="vault-ai"
REPO_URL="git@github.com:vektorsystems/vault-ai.git"
SERVICE_NAME="vault-ai-${INSTANCE_ID}"
NGINX_SITE="vault-ai-${INSTANCE_ID}"
NODE_VERSION="22.x"
PYTHON_VERSION="3.11"

CONFIG_FILE=".env-deploy-config-${INSTANCE_ID}"

if [ -f "$CONFIG_FILE" ]; then
  log_error "Config file $CONFIG_FILE already exists. Aborting to avoid overwrite."
  exit 1
fi

# Application Configuration
log_task "Configuring application settings"

# Helper: get default from .env.vault-ai.example or fallback
get_default_from_example() {
  local var="$1"
  local fallback="$2"
  local val=$(grep -E "^$var=" "$SCRIPT_DIR/../.env.vault-ai.example" | head -n1 | cut -d'=' -f2-)
  if [ -z "$val" ]; then
    echo "$fallback"
  else
    echo "$val"
  fi
}

# Defaults for each variable
DEFAULT_DB_HOST=$(get_default_from_example DB_HOST "localhost")
DEFAULT_DB_PORT=$(get_default_from_example DB_PORT "5432")
DEFAULT_DB_NAME=$(get_default_from_example DB_NAME "vault")
DEFAULT_DB_USER=$(get_default_from_example DB_USER "vault")
DEFAULT_DB_PASSWORD=$(get_default_from_example DB_PASSWORD "vault")
DEFAULT_WEBUI_NAME=$(get_default_from_example WEBUI_NAME "vault-ai")
DEFAULT_PORT=$(get_default_from_example PORT "8080")
DEFAULT_WEBUI_HOST=$(get_default_from_example WEBUI_HOST "0.0.0.0")

# Prompt for each variable
read -p "Enter DB_HOST [${DEFAULT_DB_HOST}]: " DB_HOST
DB_HOST=${DB_HOST:-$DEFAULT_DB_HOST}
read -p "Enter DB_PORT [${DEFAULT_DB_PORT}]: " DB_PORT
DB_PORT=${DB_PORT:-$DEFAULT_DB_PORT}
read -p "Enter DB_NAME [${DEFAULT_DB_NAME}]: " DB_NAME
DB_NAME=${DB_NAME:-$DEFAULT_DB_NAME}
read -p "Enter DB_USER [${DEFAULT_DB_USER}]: " DB_USER
DB_USER=${DB_USER:-$DEFAULT_DB_USER}
read -p "Enter DB_PASSWORD [${DEFAULT_DB_PASSWORD}]: " DB_PASSWORD
DB_PASSWORD=${DB_PASSWORD:-$DEFAULT_DB_PASSWORD}
read -p "Enter WEBUI_NAME [${DEFAULT_WEBUI_NAME}]: " WEBUI_NAME
WEBUI_NAME=${WEBUI_NAME:-$DEFAULT_WEBUI_NAME}
read -p "Enter PORT [${DEFAULT_PORT}]: " PORT
PORT=${PORT:-$DEFAULT_PORT}
read -p "Enter WEBUI_HOST [${DEFAULT_WEBUI_HOST}]: " WEBUI_HOST
WEBUI_HOST=${WEBUI_HOST:-$DEFAULT_WEBUI_HOST}

# Configuration Summary
log_task "Configuration Summary"

echo "--------------------------------------------------"
echo "# System/Deployment Variables"
echo "INSTANCE_ID=${INSTANCE_ID}"
echo "VAULT_DIR=${VAULT_DIR}"
echo "VAULT_USER=${VAULT_USER}"
echo "VAULT_GROUP=${VAULT_GROUP}"
echo "REPO_URL=${REPO_URL}"
echo "SERVICE_NAME=${SERVICE_NAME}"
echo "NGINX_SITE=${NGINX_SITE}"
echo "NODE_VERSION=${NODE_VERSION}"
echo "PYTHON_VERSION=${PYTHON_VERSION}"
echo

echo "# Open WebUI Application Variables"
echo "PORT=${PORT}"
echo "DB_HOST=${DB_HOST}"
echo "DB_PORT=${DB_PORT}"
echo "DB_NAME=${DB_NAME}"
echo "DB_USER=${DB_USER}"
echo "DB_PASSWORD=${DB_PASSWORD}"
echo "WEBUI_NAME=${WEBUI_NAME}"
echo "WEBUI_HOST=${WEBUI_HOST}"
echo "--------------------------------------------------"

read -p "Is this configuration correct? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    log_error "Aborted by user. No changes made."
    exit 1
fi

# Save Configuration
log_task "Saving configuration"

# Only output the variables listed by the user, grouped and ordered as specified
cat > "$CONFIG_FILE" <<EOF
# System/Deployment Variables
INSTANCE_ID=${INSTANCE_ID}
VAULT_DIR=${VAULT_DIR}
VAULT_USER=${VAULT_USER}
VAULT_GROUP=${VAULT_GROUP}
REPO_URL=${REPO_URL}
SERVICE_NAME=${SERVICE_NAME}
NGINX_SITE=${NGINX_SITE}
NODE_VERSION=${NODE_VERSION}
PYTHON_VERSION=${PYTHON_VERSION}

# Open WebUI Application Variables
PORT=${PORT}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
WEBUI_NAME=${WEBUI_NAME}
WEBUI_HOST=${WEBUI_HOST}
EOF

log_success "Configuration file ${CONFIG_FILE} created successfully."
echo "CONFIG_FILE_CREATED=$CONFIG_FILE" 