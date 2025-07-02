#!/bin/bash

# =============================================================================
# VAULT AI - PREREQUISITES INSTALLATION
# =============================================================================

# Source the logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

load_deploy_config "$SCRIPT_DIR"
deploy_check_root
deploy_check_ubuntu

log_header "VAULT AI - PREREQUISITES INSTALLATION"

# Check if running on Ubuntu
if [ "$TEST_DEPLOY" != "1" ]; then
  if ! is_ubuntu; then
      log_error "This script is designed for Ubuntu systems only"
      exit 1
  fi
fi

UBUNTU_VERSION=$(get_ubuntu_version)
log_info "Detected Ubuntu version: $UBUNTU_VERSION"

# 1.1 VERIFICATION AND SYSTEM UPDATES
log_subheader "1.1 System Dependencies Verification and Updates"

run_cmd apt update
run_cmd apt upgrade -y
run_cmd apt install -y build-essential
run_cmd apt install -y git
run_cmd apt install -y curl wget
run_cmd apt install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-dev
run_cmd apt install -y python3-pip
run_cmd curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} \| bash -
run_cmd apt install -y nodejs
run_cmd apt install -y nginx
run_cmd apt install -y certbot python3-certbot-nginx
run_cmd apt install -y gcc python3-dev
run_cmd apt install -y pandoc
run_cmd apt install -y netcat-openbsd
run_cmd apt install -y jq
run_cmd apt install -y ffmpeg libsm6 libxext6
run_cmd apt install -y python3-venv python3-pip python3-wheel
run_cmd apt install -y libgl1-mesa-glx libglib2.0-0
run_cmd apt install -y pkg-config

log_success "Basic system dependencies installed successfully"

# Verify installations
log_step "Verifying installations..."

if command_exists python${PYTHON_VERSION}; then
    log_success "Python $PYTHON_VERSION installed: $(python${PYTHON_VERSION} --version)"
else
    log_error "Python $PYTHON_VERSION installation failed"
    exit 1
fi

if command_exists node; then
    log_success "Node.js installed: $(node --version)"
else
    log_error "Node.js installation failed"
    exit 1
fi

if command_exists npm; then
    log_success "npm installed: $(npm --version)"
else
    log_error "npm installation failed"
    exit 1
fi

if command_exists nginx; then
    log_success "nginx installed: $(nginx -v 2>&1)"
else
    log_error "nginx installation failed"
    exit 1
fi

log_success "Prerequisites installation completed successfully" 