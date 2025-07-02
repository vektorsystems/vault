#!/bin/bash

# =============================================================================
# VAULT AI - APPLICATION INSTALLATION AND CONFIGURATION
# =============================================================================

# Source the logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

load_deploy_config "$SCRIPT_DIR"
deploy_check_root
deploy_check_ubuntu

log_header "VAULT AI - APPLICATION INSTALLATION AND CONFIGURATION"

# 2.1 SYSTEM CONFIGURATION
log_subheader "2.1 System Configuration"

log_step "Creating vault-ai user and group..."
if ! getent group $VAULT_GROUP >/dev/null 2>&1; then
    run_cmd groupadd $VAULT_GROUP
    log_success "Created group: $VAULT_GROUP"
fi

if ! getent passwd $VAULT_USER >/dev/null 2>&1; then
    run_cmd useradd -r -g $VAULT_GROUP -d $VAULT_DIR -s /bin/bash $VAULT_USER
    log_success "Created user: $VAULT_USER"
fi

log_step "Creating application directories..."
run_cmd mkdir -p $VAULT_DIR
run_cmd mkdir -p /var/log/vault-ai-${INSTANCE_ID}

log_step "Setting directory permissions..."
run_cmd chown -R $VAULT_USER:$VAULT_GROUP $VAULT_DIR
run_cmd chown -R $VAULT_USER:$VAULT_GROUP /var/log/vault-ai-${INSTANCE_ID}

log_success "System configuration completed"

# 2.2 REPOSITORY SETUP
log_subheader "2.2 Repository Setup"

log_step "Cloning repository..."
run_cd $VAULT_DIR
if [ ! -d ".git" ]; then
    run_cmd sudo -u $VAULT_USER git clone $REPO_URL .
    log_success "Repository cloned successfully"
else
    log_info "Repository already exists, pulling latest changes..."
    run_cmd sudo -u $VAULT_USER git pull
fi

# 2.3 ENVIRONMENT CONFIGURATION
log_subheader "2.3 Environment Configuration"

log_step "Creating .env file from example..."
run_cd $VAULT_DIR
if [ ! -f ".env" ]; then
    if [ -f ".env.vault-ai.example" ]; then
        run_cmd sudo -u $VAULT_USER cp .env.vault-ai.example .env
        log_success "Created .env from .env.vault-ai.example"
    elif [ -f ".env.example" ]; then
        run_cmd sudo -u $VAULT_USER cp .env.example .env
        log_success "Created .env from .env.example"
    else
        run_cmd sudo -u $VAULT_USER touch .env
        log_warn "No .env.example found, created empty .env file"
    fi
else
    log_info ".env file already exists"
fi

log_step "Generating WEBUI_SECRET_KEY..."
SECRET_KEY=$(openssl rand -hex 32)
# Update or add WEBUI_SECRET_KEY in .env
if sudo -u $VAULT_USER grep -q "^WEBUI_SECRET_KEY=" .env; then
    run_cmd sudo -u $VAULT_USER sed -i "s/^WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=$SECRET_KEY/" .env
else
    run_cmd sudo -u $VAULT_USER bash -c "echo 'WEBUI_SECRET_KEY=$SECRET_KEY' >> .env"
fi

log_step "Updating production settings..."
# Update ENV to production
run_cmd sudo -u $VAULT_USER sed -i "s/^ENV=.*/ENV=prod/" .env
# Update PORT if needed
run_cmd sudo -u $VAULT_USER sed -i "s/^PORT=.*/PORT=8080/" .env

log_success "Environment configuration completed"

# 2.4 PYTHON ENVIRONMENT SETUP
log_subheader "2.4 Python Environment Setup"

log_step "Creating Python virtual environment..."
run_cd $VAULT_DIR
run_cmd sudo -u $VAULT_USER python${PYTHON_VERSION} -m venv venv

log_step "Activating virtual environment and upgrading pip..."
run_cmd sudo -u $VAULT_USER bash -c "source venv/bin/activate && pip install --upgrade pip"

log_step "Installing uv package manager..."
run_cmd sudo -u $VAULT_USER bash -c "source venv/bin/activate && pip install uv"

log_step "Installing Python dependencies..."
run_cd $VAULT_DIR/backend
run_cmd sudo -u $VAULT_USER bash -c "source ../venv/bin/activate && uv pip install --system -r requirements.txt"

log_success "Python environment setup completed"

# 2.5 NODE.JS DEPENDENCIES SETUP
log_subheader "2.5 Node.js Dependencies Setup"

log_step "Installing Node.js dependencies..."
run_cd $VAULT_DIR
run_cmd sudo -u $VAULT_USER npm ci

log_success "Node.js dependencies installed"

# 2.6 INITIAL VERIFICATIONS
log_subheader "2.6 Initial Verifications"

log_step "Verifying Python installation..."
if run_cmd sudo -u $VAULT_USER bash -c "source $VAULT_DIR/venv/bin/activate && python --version"; then
    log_success "Python environment verified"
else
    log_error "Python environment verification failed"
    exit 1
fi

log_step "Verifying Node.js dependencies..."
if dir_exists "$VAULT_DIR/node_modules"; then
    log_success "Node.js dependencies verified"
else
    log_error "Node.js dependencies verification failed"
    exit 1
fi

log_step "Verifying .env file..."
if file_exists "$VAULT_DIR/.env"; then
    log_success ".env file verified"
else
    log_error ".env file verification failed"
    exit 1
fi

log_success "Installation and configuration completed successfully" 