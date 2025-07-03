#!/bin/bash

# =============================================================================
# VAULT AI - APPLICATION INSTALLATION
# =============================================================================

# Source the logger and common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

# System Configuration
log_task "Configuring system"

log_info "Creating vault-ai user and group..."
run_cmd "useradd -r -s /bin/false $VAULT_USER"
run_cmd "groupadd $VAULT_GROUP"
run_cmd "usermod -a -G $VAULT_GROUP $VAULT_USER"
run_cmd "mkdir -p /var/log/vault-ai"
run_cmd "chown -R $VAULT_USER:$VAULT_GROUP /var/log/vault-ai"

# Repository Setup
log_task "Setting up repository"

log_info "Cloning repository..."
run_cmd "git clone $REPO_URL $VAULT_AI_DIR"
run_cd "$VAULT_AI_DIR"

# Python Environment Setup
log_task "Setting up Python environment"

log_info "Creating Python virtual environment..."
run_cd "$VAULT_AI_DIR"
run_cmd "python3.11 -m venv venv"

log_info "Activating virtual environment and upgrading pip..."
run_cmd "bash -c 'source $VAULT_AI_DIR/venv/bin/activate && pip install --upgrade pip'"

log_info "Installing uv package manager..."
run_cmd "bash -c 'source $VAULT_AI_DIR/venv/bin/activate && pip install uv'"

log_info "Installing Python dependencies..."
run_cd "$VAULT_AI_DIR/backend"
run_cmd "bash -c 'source $VAULT_AI_DIR/venv/bin/activate && uv pip install --system -r requirements.txt'"

log_success "Python environment setup completed"

# Node.js Setup
log_task "Setting up Node.js dependencies"

log_info "Installing Node.js dependencies..."
run_cd "$VAULT_AI_DIR"
run_cmd "npm ci"
log_success "Node.js dependencies installed"

# Verification
log_task "Running initial verifications"

log_info "Verifying Python installation..."
run_cmd "bash -c 'source $VAULT_AI_DIR/venv/bin/activate && python --version'"
log_success "Python environment verified"

log_info "Verifying Node.js dependencies..."
if [ "$TEST_DEPLOY" = "1" ]; then
    log_success "Node.js dependencies would be verified in test mode"
else
    if [ -d "node_modules" ]; then
        log_success "Node.js dependencies verified"
    else
        log_error "Node.js dependencies not found"
        exit 1
    fi
fi

log_success "Installation and configuration completed successfully"
