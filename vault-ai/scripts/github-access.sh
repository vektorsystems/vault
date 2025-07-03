#!/bin/bash

# =============================================================================
# VAULT AI - GITHUB ACCESS CONFIGURATION
# =============================================================================

# Source the logger and common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

# Check if instance ID is provided
if [ -z "$1" ]; then
    log_error "Instance ID not provided"
    exit 1
fi

# Load configuration
INSTANCE_ID="$1"
SECTION_NUM="${2:-0}"
CONFIG_FILE=".env-deploy-config-$INSTANCE_ID"

load_deploy_config "$SCRIPT_DIR" "$CONFIG_FILE"

# Check if running as root
deploy_check_root

# Check if running on Ubuntu
deploy_check_ubuntu

# Set SSH directory based on test mode
if [ "$TEST_DEPLOY" = "1" ]; then
    SSH_DIR="$SCRIPT_DIR/../test/ssh"
    mkdir -p "$SSH_DIR"
else
    SSH_DIR="/root/.ssh"
fi

log_task "Installing Git"
run_cmd "apt-get update && apt-get install -y git" \
    "Failed to install Git" \
    "Git installed successfully"

log_task "Setting up SSH directory"
run_cmd "mkdir -p $SSH_DIR && chmod 700 $SSH_DIR" \
    "Failed to create SSH directory" \
    "SSH directory created successfully"

log_task "Installing deploy key"
if [ "$TEST_DEPLOY" = "1" ]; then
    cat > "$SSH_DIR/vault_ia_deploy_key" << 'EOL'
-----MY SSH KEY-----
EOL
else
    run_cmd "cat > $SSH_DIR/vault_ia_deploy_key << 'EOL'
-----MY SSH KEY-----
EOL" \
    "Failed to create deploy key" \
    "Deploy key created successfully"
fi

run_cmd "chmod 600 $SSH_DIR/vault_ia_deploy_key" \
    "Failed to set permissions on deploy key" \
    "Deploy key permissions set successfully"

log_task "Adding GitHub to known hosts"
run_cmd "ssh-keyscan github.com >> $SSH_DIR/known_hosts" \
    "Failed to add GitHub to known hosts" \
    "GitHub added to known hosts successfully"

log_task "Testing GitHub access"
run_cmd "ssh -T -i $SSH_DIR/vault_ia_deploy_key git@github.com" \
    "Failed to verify GitHub access" \
    "GitHub access verified successfully"

log_success "GitHub access configuration completed successfully"
exit 0 