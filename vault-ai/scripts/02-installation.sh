#!/bin/bash

# =============================================================================
# VAULT AI - APPLICATION INSTALLATION AND CONFIGURATION
# =============================================================================

# Source the logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

INSTANCE_ID="$1"
STEP_PREFIX="$2"
CONFIG_FILE=".env-deploy-config-${INSTANCE_ID}"
load_deploy_config "$SCRIPT_DIR" "$SCRIPT_DIR/../$CONFIG_FILE"
deploy_check_root

# Only show header if running standalone (no step prefix)
if [ -z "$STEP_PREFIX" ]; then
  log_header "VAULT AI - APPLICATION INSTALLATION AND CONFIGURATION"
fi

deploy_check_ubuntu

# Check if running on Ubuntu
if [ "$TEST_DEPLOY" != "1" ]; then
  if ! is_ubuntu; then
      log_error "This script is designed for Ubuntu systems only"
      exit 1
  fi
fi

# System Configuration
log_task "Configuring system"

log_info "Creating vault-ai user and group..."
if ! getent group $VAULT_GROUP >/dev/null 2>&1; then
    run_cmd groupadd $VAULT_GROUP
    log_success "Created group: $VAULT_GROUP"
fi

if ! getent passwd $VAULT_USER >/dev/null 2>&1; then
    run_cmd useradd -r -g $VAULT_GROUP -d $VAULT_DIR -s /bin/bash $VAULT_USER
    log_success "Created user: $VAULT_USER"
fi

log_info "Creating application directories..."
run_cmd mkdir -p $VAULT_DIR
run_cmd mkdir -p /var/log/vault-ai-${INSTANCE_ID}

log_info "Setting directory permissions..."
run_cmd chown -R $VAULT_USER:$VAULT_GROUP $VAULT_DIR
run_cmd chown -R $VAULT_USER:$VAULT_GROUP /var/log/vault-ai-${INSTANCE_ID}

log_success "System configuration completed"

# Repository Setup
log_task "Setting up repository"

log_info "Cloning repository..."
run_cd $VAULT_DIR
if [ "$TEST_DEPLOY" = "1" ]; then
    log_success "Repository cloned successfully"
else
    if [ ! -d ".git" ]; then
        run_cmd sudo -u $VAULT_USER git clone $REPO_URL .
        log_success "Repository cloned successfully"
    else
        log_info "Repository already exists, pulling latest changes..."
        run_cmd sudo -u $VAULT_USER git pull
    fi
fi

# Environment Configuration
log_task "Configuring environment"

log_info "Creating .env file from example..."
run_cd $VAULT_DIR
if [ ! -f ".env" ]; then
    if [ -f ".env.vault-ai.example" ]; then
        run_cmd cp "$SCRIPT_DIR/../.env.vault-ai.example" .env.tmp
        while IFS='=' read -r var val; do
          [[ -z "$var" || "$var" =~ ^# ]] && continue
          if run_cmd grep -q "^$var=" .env.tmp; then
              run_cmd sed -i "s|^$var=.*|$var=$val|" .env.tmp
          else
              run_cmd bash -c "echo '$var=$val' >> .env.tmp"
          fi
        done < "$SCRIPT_DIR/../$CONFIG_FILE"
        run_cmd mv .env.tmp .env
        log_success "Created .env from .env.vault-ai.example"
    elif [ -f ".env.example" ]; then
        run_cmd cp .env.example .env
        log_success "Created .env from .env.example"
    else
        run_cmd touch .env
        log_warn "No .env.example found, created empty .env file"
    fi
else
    log_info ".env file already exists"
fi

while IFS='=' read -r var val; do
  [[ -z "$var" || "$var" =~ ^# ]] && continue
  if run_cmd grep -q "^$var=" .env; then
      run_cmd sed -i "s|^$var=.*|$var=$val|" .env
  else
      run_cmd bash -c "echo '$var=$val' >> .env"
  fi
done < "$SCRIPT_DIR/../$CONFIG_FILE"

log_info "Generating WEBUI_SECRET_KEY..."
SECRET_KEY=$(openssl rand -hex 32)
if run_cmd grep -q "^WEBUI_SECRET_KEY=" .env; then
    run_cmd sed -i "s/^WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=$SECRET_KEY/" .env
else
    run_cmd bash -c "echo 'WEBUI_SECRET_KEY=$SECRET_KEY' >> .env"
fi

log_info "Updating production settings..."
run_cmd sed -i "s/^ENV=.*/ENV=prod/" .env
run_cmd sed -i "s/^PORT=.*/PORT=$PORT/" .env

log_success "Environment configuration completed"

# Python Environment Setup
log_task "Setting up Python environment"

log_info "Creating Python virtual environment..."
run_cd $VAULT_DIR
run_cmd sudo -u $VAULT_USER python${PYTHON_VERSION} -m venv venv

log_info "Activating virtual environment and upgrading pip..."
run_cmd sudo -u $VAULT_USER bash -c "source venv/bin/activate && pip install --upgrade pip"

log_info "Installing uv package manager..."
run_cmd sudo -u $VAULT_USER bash -c "source venv/bin/activate && pip install uv"

log_info "Installing Python dependencies..."
run_cd $VAULT_DIR/backend
run_cmd sudo -u $VAULT_USER bash -c "source ../venv/bin/activate && uv pip install --system -r requirements.txt"

log_success "Python environment setup completed"

# Node.js Dependencies Setup
log_task "Setting up Node.js dependencies"

log_info "Installing Node.js dependencies..."
run_cd $VAULT_DIR
run_cmd sudo -u $VAULT_USER npm ci

log_success "Node.js dependencies installed"

# Initial Verifications
log_task "Running initial verifications"

log_info "Verifying Python installation..."
if run_cmd bash -c "source $VAULT_DIR/venv/bin/activate && python --version"; then
    log_success "Python environment verified"
else
    log_error "Python environment verification failed"
    exit 1
fi

log_info "Verifying Node.js dependencies..."
if dir_exists "$VAULT_DIR/node_modules"; then
    log_success "Node.js dependencies verified"
else
    log_error "Node.js dependencies verification failed"
    exit 1
fi

log_info "Verifying .env file..."
if file_exists "$VAULT_DIR/.env"; then
    log_success ".env file verified"
else
    log_error ".env file verification failed"
    exit 1
fi

log_success "Installation and configuration completed successfully"

# Print Installation Details
log_section "2.5" "Installation Details"
if [ "$TEST_DEPLOY" = "1" ]; then
    log_info "Installation directory: $VAULT_DIR"
    log_info "Service name: $SERVICE_NAME"
    log_info "Web UI port: $PORT"
    log_info "Database: $DB_NAME on $DB_HOST:$DB_PORT"
    log_info "Web UI name: $WEBUI_NAME"
else
    log_info "Installation directory: $VAULT_DIR"
    log_info "Service name: $SERVICE_NAME"
    log_info "Web UI port: $(grep '^PORT=' $ENV_FILE | cut -d'=' -f2)"
    log_info "Database: $(grep '^DB_NAME=' $ENV_FILE | cut -d'=' -f2) on $(grep '^DB_HOST=' $ENV_FILE | cut -d'=' -f2):$(grep '^DB_PORT=' $ENV_FILE | cut -d'=' -f2)"
    log_info "Web UI name: $(grep '^WEBUI_NAME=' $ENV_FILE | cut -d'=' -f2)"
fi 