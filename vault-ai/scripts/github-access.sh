#!/bin/bash

# =============================================================================
# VAULT AI - GITHUB ACCESS CONFIGURATION
# =============================================================================

# Source the logger and common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

# Install Git
log_task "Installing Git"
run_cmd "apt-get install -y git"

# Set up SSH directory
log_task "Setting up SSH directory"
run_cmd "mkdir -p /root/.ssh && chmod 700 /root/.ssh"

# Install deploy key
log_task "Installing deploy key"
run_cmd "cat > /root/.ssh/vault_ia_deploy_key << 'EOL'
-----BEGIN OPENSSH PRIVATE KEY-----
XXXXXXXX
-----END OPENSSH PRIVATE KEY-----
EOL"

run_cmd "chmod 600 /root/.ssh/vault_ia_deploy_key"

# Add GitHub to known hosts
log_task "Adding GitHub to known hosts"
run_cmd "ssh-keyscan github.com >> /root/.ssh/known_hosts"

log_success "GitHub access configuration completed successfully" 