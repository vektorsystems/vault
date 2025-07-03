#!/usr/bin/env bash

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

# Define deployment scripts
CONFIG_INSTALLER_SCRIPT="config-installer"
PREREQUISITES_SCRIPT="prerequisites"
GITHUB_ACCESS_SCRIPT="github-access"
APP_INSTALL_SCRIPT="installation"
SERVICES_SCRIPT="services"
STARTUP_SCRIPT="startup"

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
CONFIG_INSTALLER_OUTPUT=$(bash "$SCRIPT_DIR/scripts/${CONFIG_INSTALLER_SCRIPT}.sh" $TEST_ARGS)
if [ $? -ne 0 ]; then
  log_error "Configuration was not confirmed. Exiting."
  exit 1
fi

# Parse config file name and INSTANCE_ID
CONFIG_FILE=$(echo "$CONFIG_INSTALLER_OUTPUT" | grep CONFIG_FILE_CREATED | cut -d'=' -f2)
if [ -z "$CONFIG_FILE" ]; then
  log_error "Could not determine config file path"
  exit 1
fi

# Make sure we use absolute path for config file
if [[ "$CONFIG_FILE" != /* ]]; then
  CONFIG_FILE="$SCRIPT_DIR/$CONFIG_FILE"
fi

INSTANCE_ID=$(grep INSTANCE_ID "$CONFIG_FILE" | cut -d'=' -f2)

if [ ! -f "$CONFIG_FILE" ]; then
  log_error "Configuration file not found: $CONFIG_FILE"
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
if bash "$SCRIPT_DIR/scripts/${PREREQUISITES_SCRIPT}.sh" "$INSTANCE_ID" "2.1" $TEST_ARGS; then
    log_success "Prerequisites installation completed"
else
    log_error "Prerequisites installation failed"
    exit 1
fi

# GitHub Access Configuration
log_subsection "2.2" "GitHub Access Configuration"
if bash "$SCRIPT_DIR/scripts/${GITHUB_ACCESS_SCRIPT}.sh" "$INSTANCE_ID" "2.2" $TEST_ARGS; then
    log_success "GitHub access configuration completed"
else
    log_error "GitHub access configuration failed"
    exit 1
fi

# Application Installation
log_subsection "2.3" "Application Installation"
if bash "$SCRIPT_DIR/scripts/${APP_INSTALL_SCRIPT}.sh" "$INSTANCE_ID" "2.3" $TEST_ARGS; then
    log_success "Application installation completed"
else
    log_error "Application installation failed"
    exit 1
fi

# Services Configuration
log_subsection "2.4" "Services Configuration"
if bash "$SCRIPT_DIR/scripts/${SERVICES_SCRIPT}.sh" "$INSTANCE_ID" "2.4" $TEST_ARGS; then
    log_success "Services configuration completed"
else
    log_error "Services configuration failed"
    exit 1
fi

# Startup and Verification
log_subsection "2.5" "Startup and Verification"
if bash "$SCRIPT_DIR/scripts/${STARTUP_SCRIPT}.sh" "$INSTANCE_ID" "2.5" $TEST_ARGS; then
    log_success "Startup and verification completed"
else
    log_error "Startup and verification failed"
    exit 1
fi

# Calculate installation time
END_TIME=$(date +%s)
INSTALLATION_TIME=$((END_TIME - START_TIME))

# Installation Summary
log_header "VAULT AI - INSTALLATION SUMMARY"

log_clean "Installation Details:"
log_clean "  • Instance ID: ${INSTANCE_ID}"
log_clean "  • Installation Directory: ${VAULT_DIR}"
log_clean "  • Service Name: ${SERVICE_NAME}"
log_clean "  • Nginx Site: ${NGINX_SITE}"
log_clean "  • Backend Port: ${PORT}"
log_clean "  • Frontend: http://localhost"
log_clean "  • Health Check: http://localhost/health"

log_clean ""
log_clean "Service Management Commands:"
log_clean "  • Check status: systemctl status ${SERVICE_NAME}"
log_clean "  • View logs: journalctl -u ${SERVICE_NAME} -f"
log_clean "  • Restart service: systemctl restart ${SERVICE_NAME}"
log_clean "  • Stop service: systemctl stop ${SERVICE_NAME}"

log_clean ""
log_clean "Nginx Management Commands:"
log_clean "  • Check nginx status: systemctl status nginx"
log_clean "  • Test nginx config: nginx -t"
log_clean "  • Reload nginx: systemctl reload nginx"

log_clean ""
log_clean "SSL Configuration (Optional):"
log_clean "  • Configure SSL: certbot --nginx -d your-domain.com"
log_clean "  • Auto-renewal: certbot renew --dry-run"

log_clean ""
log_clean "Total installation time: ${INSTALLATION_TIME} seconds"
log_clean "You can now access Vault AI at: http://localhost"
log_clean "Health check: http://localhost/health"

log_color "blue" "============================================================================="
log_success "Deployment completed successfully!"
log_color "blue" "============================================================================="
