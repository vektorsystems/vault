#!/bin/bash

# =============================================================================
# VAULT AI - NATIVE DEPLOYMENT SCRIPT
# =============================================================================
# This script installs Vault AI on Ubuntu 22.04+
# Usage: bash deploy-native.sh [--test]
# =============================================================================

# Source the logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/scripts/logger.sh"
source "$SCRIPT_DIR/scripts/common.sh"

# Print the main header at the very start of the script
log_header "VAULT AI - NATIVE DEPLOYMENT SCRIPT"

# Parse --test flag
TEST_ARGS=""
for arg in "$@"; do
  if [[ "$arg" == "--test" ]]; then
    export TEST_DEPLOY=1
    TEST_ARGS="--test"
  fi
done

# Section 1: Deploy Config Installer
log_section "1" "Deploy Config Installer"

# Always run config installer and capture output
CONFIG_INSTALLER_OUTPUT=$(bash "$SCRIPT_DIR/deploy-config-installer.sh" $TEST_ARGS)
if [ $? -ne 0 ]; then
  log_error "Configuration was not confirmed. Exiting."
  exit 1
fi

# Parse config file name and INSTANCE_ID
CONFIG_FILE=$(echo "$CONFIG_INSTALLER_OUTPUT" | grep CONFIG_FILE_CREATED | cut -d'=' -f2)
INSTANCE_ID=$(grep INSTANCE_ID "$CONFIG_FILE" | cut -d'=' -f2)

if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
  log_error "Configuration file was not created. Exiting."
  exit 1
fi

# Load config
load_deploy_config "$SCRIPT_DIR" "$CONFIG_FILE"
VAULT_DIR=$(grep VAULT_DIR "$CONFIG_FILE" | cut -d'=' -f2)

if [ "$TEST_DEPLOY" = "1" ]; then
  log_test_mode
fi

# Installation start time
START_TIME=$(date +%s)

# Add confirmation prompt after config file is created and validated, before installation steps
read -p "Do you want to start the deploy now? [y/N]: " START_DEPLOY
START_DEPLOY=${START_DEPLOY:-N}
if [[ ! $START_DEPLOY =~ ^[Yy]$ ]]; then
  log_info "You can now manually edit ${CONFIG_FILE} if needed. Run ./deploy.sh $INSTANCE_ID${TEST_ARGS:+ $TEST_ARGS} when ready."
  exit 0
fi

# Section 2: Installation Process
log_section "2" "Installation Process"

# Prerequisites
log_subsection "2.1" "Prerequisites Installation"
if bash "$SCRIPT_DIR/scripts/01-prerequisites.sh" "$INSTANCE_ID" "2.1" $TEST_ARGS; then
    log_success "Prerequisites installation completed"
else
    log_error "Prerequisites installation failed"
    exit 1
fi

# Application Installation
log_subsection "2.2" "Application Installation"
if bash "$SCRIPT_DIR/scripts/02-installation.sh" "$INSTANCE_ID" "2.2" $TEST_ARGS; then
    log_success "Application installation completed"
else
    log_error "Application installation failed"
    exit 1
fi

# Services Configuration
log_subsection "2.3" "Services Configuration"
if bash "$SCRIPT_DIR/scripts/03-services.sh" "$INSTANCE_ID" "2.3" $TEST_ARGS; then
    log_success "Services configuration completed"
else
    log_error "Services configuration failed"
    exit 1
fi

# Startup and Verification
log_subsection "2.4" "Startup and Verification"
if bash "$SCRIPT_DIR/scripts/04-startup.sh" "$INSTANCE_ID" "2.4" $TEST_ARGS; then
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