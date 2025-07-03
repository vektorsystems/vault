#!/bin/bash

# =============================================================================
# VAULT AI - DEPLOYMENT
# =============================================================================
# This script installs Vault AI
# Usage: bash deploy.sh [--test]
# =============================================================================

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Source the logger and common utilities
source "$SCRIPT_DIR/scripts/logger.sh"
source "$SCRIPT_DIR/scripts/common.sh"

# Print the main header
log_header "VAULT AI - DEPLOYMENT"

# Parse test flag
TEST_DEPLOY=0
for arg in "$@"; do
  case "$arg" in
    --test)
      TEST_DEPLOY=1
      ;;
  esac
done

# Export TEST_DEPLOY for other scripts
export TEST_DEPLOY

# Configuration Installer
log_section "1" "Deploy Config Installer"

# Source configuration
eval "$("$SCRIPT_DIR/scripts/config-installer.sh" "$@")"

# Installation Process
log_section "2" "Installation Process"

# Prerequisites Installation
log_subsection "2.1" "Prerequisites Installation"
if ! "$SCRIPT_DIR/scripts/prerequisites.sh"; then
    log_error "Prerequisites installation failed"
    exit 1
fi
log_success "Prerequisites installation completed"

# GitHub Access Configuration
log_subsection "2.2" "GitHub Access Configuration"
if ! "$SCRIPT_DIR/scripts/github-access.sh"; then
    log_error "GitHub access configuration failed"
    exit 1
fi
log_success "GitHub access configuration completed"

# Application Installation
log_subsection "2.3" "Application Installation"
if ! "$SCRIPT_DIR/scripts/installation.sh"; then
    log_error "Application installation failed"
    exit 1
fi
log_success "Application installation completed"

# Services Configuration
log_subsection "2.4" "Services Configuration"
if ! "$SCRIPT_DIR/scripts/services.sh"; then
    log_error "Services configuration failed"
    exit 1
fi
log_success "Services configuration completed"

# Startup and Verification
log_subsection "2.5" "Startup and Verification"
if ! "$SCRIPT_DIR/scripts/startup.sh"; then
    log_error "Startup and verification failed"
    exit 1
fi
log_success "Startup and verification completed"

# Installation Summary
log_header "VAULT AI - INSTALLATION SUMMARY"

log_clean "Installation Details:"
log_clean "  • Installation Directory: ${VAULT_AI_DIR}"
log_clean "  • Service Name: ${SERVICE_NAME}"
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
log_clean "Total installation time: $SECONDS seconds"
log_clean "You can now access Vault AI at: http://localhost"
log_clean "Health check: http://localhost/health"

log_color "blue" "============================================================================="
log_success "Deployment completed successfully"
log_color "blue" "============================================================================="
