#!/bin/bash

# =============================================================================
# VAULT AI - NATIVE DEPLOYMENT SCRIPT
# =============================================================================
# This script installs Vault AI on Ubuntu 22.04+
# Usage: bash deploy-native.sh [--test]
# =============================================================================

# Parse arguments for --test
for arg in "$@"; do
  if [[ "$arg" == "--test" ]]; then
    export TEST_DEPLOY=1
  fi
 done

# Source the logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/scripts/logger.sh"
source "$SCRIPT_DIR/scripts/common.sh"

# Configuration
DEPLOY_CONFIG_PATH="$SCRIPT_DIR/.env-deploy-config"
INSTANCE_ID="1"
VAULT_DIR="/opt/vault-ai-${INSTANCE_ID}"

log_header "VAULT AI - NATIVE DEPLOYMENT SCRIPT"

if [ "$TEST_DEPLOY" = "1" ]; then
  log_info "Running in TEST mode: no real changes will be made."
fi

# Check if running as root
if [ "$TEST_DEPLOY" != "1" ]; then
  if ! is_root; then
      log_error "This script must be run as root (use sudo)"
      exit 1
  fi
fi

# Check if running on Ubuntu
if [ "$TEST_DEPLOY" != "1" ]; then
  if ! is_ubuntu; then
      log_error "This script is designed for Ubuntu systems only"
      exit 1
  fi
fi

UBUNTU_VERSION=$(get_ubuntu_version)
log_info "Detected Ubuntu version: $UBUNTU_VERSION"

# Check if already installed
if [ -d "$VAULT_DIR" ]; then
    log_warn "Vault AI appears to be already installed at $VAULT_DIR"
    read -p "Do you want to continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
fi

# Installation start time
START_TIME=$(date +%s)

# Execute installation scripts in sequence
log_subheader "Starting Installation Process"

# 1. Prerequisites
log_step "Executing prerequisites installation..."
if bash "$SCRIPT_DIR/scripts/01-prerequisites.sh"; then
    log_success "Prerequisites installation completed"
else
    log_error "Prerequisites installation failed"
    exit 1
fi

# 2. Application Installation
log_step "Executing application installation..."
if bash "$SCRIPT_DIR/scripts/02-installation.sh"; then
    log_success "Application installation completed"
else
    log_error "Application installation failed"
    exit 1
fi

# 3. Services Configuration
log_step "Executing services configuration..."
if bash "$SCRIPT_DIR/scripts/03-services.sh"; then
    log_success "Services configuration completed"
else
    log_error "Services configuration failed"
    exit 1
fi

# 4. Startup and Verification
log_step "Executing startup and verification..."
if bash "$SCRIPT_DIR/scripts/04-startup.sh"; then
    log_success "Startup and verification completed"
else
    log_error "Startup and verification failed"
    exit 1
fi

# Calculate installation time
END_TIME=$(date +%s)
INSTALLATION_TIME=$((END_TIME - START_TIME))

# Final summary
log_header "INSTALLATION COMPLETED SUCCESSFULLY"
log_info "Total installation time: ${INSTALLATION_TIME} seconds"
log_info "Vault AI is now running and accessible at: http://localhost"
log_info "Health check: http://localhost/health"

log_success "Deployment completed successfully!" 