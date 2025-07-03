#!/bin/bash

# =============================================================================
# VAULT AI - STARTUP AND VERIFICATION
# =============================================================================

# Source the logger and common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

# Start services
log_task "Starting services"

log_info "Starting vault-ai service..."
run_cmd "systemctl start $SERVICE_NAME"

log_info "Waiting for service to start..."
run_cmd "sleep 5"

log_info "Checking service status..."
if run_cmd "systemctl is-active --quiet $SERVICE_NAME"; then
    log_success "Vault AI service is running"
else
    log_error "Vault AI service failed to start"
    exit 1
fi

log_info "Starting nginx service..."
run_cmd "systemctl start nginx"

log_info "Checking nginx status..."
if run_cmd "systemctl is-active --quiet nginx"; then
    log_success "Nginx service is running"
else
    log_error "Nginx service failed to start"
    exit 1
fi

# Health checks
log_task "Running health checks"

log_info "Testing backend health endpoint..."
if run_cmd "curl -s http://localhost:$PORT/health | grep -q 'true'"; then
    log_success "Backend health check passed"
else
    log_error "Backend health check failed"
    exit 1
fi

log_info "Testing nginx proxy..."
if run_cmd "curl -s http://localhost/health | grep -q 'true'"; then
    log_success "Nginx proxy test passed"
else
    log_error "Nginx proxy test failed"
    exit 1
fi

log_info "Checking service logs..."
if run_cmd "journalctl -u $SERVICE_NAME --no-pager -n 10 | grep -q 'Application startup complete'"; then
    log_success "Service logs show successful startup"
else
    log_error "Service startup logs not found"
    exit 1
fi

# Build frontend
log_task "Building frontend"

log_info "Building frontend..."
run_cd "$VAULT_AI_DIR"
if run_cmd "npm run build"; then
    log_success "Frontend build completed successfully"
else
    log_error "Frontend build failed"
    exit 1
fi

log_info "Verifying frontend build..."
if run_cmd "[ -d '$VAULT_AI_DIR/build' ]"; then
    log_success "Frontend build verified"
else
    log_error "Frontend build verification failed"
    exit 1
fi

log_success "Startup and verification completed successfully"
