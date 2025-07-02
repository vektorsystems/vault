#!/bin/bash

# =============================================================================
# VAULT AI - DEPLOY CONFIG INSTALLER
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
if ! source "$SCRIPT_DIR/scripts/logger.sh"; then
  echo "[ERROR] Failed to source logger.sh" >&2
  exit 1
fi
if ! source "$SCRIPT_DIR/scripts/common.sh"; then
  log_error "Failed to source common.sh"
  exit 1
fi

# Parse --test flag
for arg in "$@"; do
  if [[ "$arg" == "--test" ]]; then
    export TEST_DEPLOY=1
    log_info "Running in TEST mode: no real changes will be made."
  fi
done

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

# Show summary
log_info "Configuration to be written to ${CONFIG_FILE}:"
echo "--------------------------------------------------"
echo "INSTANCE_ID=${INSTANCE_ID}"
echo "VAULT_DIR=${VAULT_DIR}"
echo "VAULT_USER=${VAULT_USER}"
echo "VAULT_GROUP=${VAULT_GROUP}"
echo "REPO_URL=${REPO_URL}"
echo "SERVICE_NAME=${SERVICE_NAME}"
echo "NGINX_SITE=${NGINX_SITE}"
echo "NODE_VERSION=${NODE_VERSION}"
echo "PYTHON_VERSION=${PYTHON_VERSION}"
echo "--------------------------------------------------"

read -p "Is this configuration correct? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    log_error "Aborted by user. No changes made."
    exit 1
fi

# Write config file
cat > "$CONFIG_FILE" <<EOF
INSTANCE_ID=${INSTANCE_ID}
VAULT_DIR=${VAULT_DIR}
VAULT_USER=${VAULT_USER}
VAULT_GROUP=${VAULT_GROUP}
REPO_URL=${REPO_URL}
SERVICE_NAME=${SERVICE_NAME}
NGINX_SITE=${NGINX_SITE}
NODE_VERSION=${NODE_VERSION}
PYTHON_VERSION=${PYTHON_VERSION}
EOF

log_success "Configuration file ${CONFIG_FILE} created successfully."
echo "CONFIG_FILE_CREATED=$CONFIG_FILE"

read -p "Do you want to start the deploy now? [y/N]: " START_DEPLOY
START_DEPLOY=${START_DEPLOY:-N}
if [[ $START_DEPLOY =~ ^[Yy]$ ]]; then
    log_info "Starting deployment..."
    echo "DEPLOY_START=1"
    if [ "$TEST_DEPLOY" = "1" ]; then
      bash "$SCRIPT_DIR/deploy.sh" "$INSTANCE_ID" --test
    else
      bash "$SCRIPT_DIR/deploy.sh" "$INSTANCE_ID"
    fi
else
    if [ "$TEST_DEPLOY" = "1" ]; then
      log_info "You can now manually edit ${CONFIG_FILE} if needed. Run ./deploy.sh $INSTANCE_ID --test when ready."
    else
      log_info "You can now manually edit ${CONFIG_FILE} if needed. Run ./deploy.sh $INSTANCE_ID when ready."
    fi
fi