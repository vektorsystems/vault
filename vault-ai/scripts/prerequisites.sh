#!/bin/bash

# =============================================================================
# VAULT AI - PREREQUISITES INSTALLATION
# =============================================================================

# Source the logger and common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

# Basic system dependencies
log_task "Installing system dependencies"

run_cmd "apt update"
run_cmd "apt upgrade -y"
run_cmd "apt install -y build-essential"
run_cmd "apt install -y git"
run_cmd "apt install -y curl wget"
run_cmd "apt install -y python python-venv python-dev"
run_cmd "apt install -y python3-pip"
run_cmd "curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -"
run_cmd "apt install -y nodejs"
run_cmd "apt install -y nginx"
run_cmd "apt install -y certbot python3-certbot-nginx"
run_cmd "apt install -y gcc python3-dev"
run_cmd "apt install -y pandoc"
run_cmd "apt install -y netcat-openbsd"
run_cmd "apt install -y jq"
run_cmd "apt install -y ffmpeg libsm6 libxext6"
run_cmd "apt install -y python3-venv python3-pip python3-wheel"
run_cmd "apt install -y libgl1-mesa-glx libglib2.0-0"
run_cmd "apt install -y pkg-config"

log_success "Basic system dependencies installed successfully"

# Verify installations
log_task "Verifying installations"

run_cmd "python${PYTHON_VERSION} --version"
run_cmd "node --version"
run_cmd "npm --version"
run_cmd "nginx -v"

log_success "Prerequisites installation completed successfully" 