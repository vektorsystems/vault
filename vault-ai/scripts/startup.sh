#!/bin/bash

# =============================================================================
# VAULT AI - STARTUP AND VERIFICATION
# =============================================================================

# Source the logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

INSTANCE_ID="$1"
STEP_PREFIX="$2"
CONFIG_FILE=".env-deploy-config-${INSTANCE_ID}"
load_deploy_config "$SCRIPT_DIR" "$SCRIPT_DIR/../$CONFIG_FILE"

# Only show header if running standalone (no step prefix)
if [ -z "$STEP_PREFIX" ]; then
  log_header "VAULT AI - STARTUP AND VERIFICATION"
fi

deploy_check_ubuntu

# Service Startup
log_task "Starting services"

log_info "Starting vault-ai service..."
run_cmd systemctl start ${SERVICE_NAME}

log_info "Waiting for service to start..."
sleep 5

log_info "Checking service status..."
if run_check systemctl is-active --quiet ${SERVICE_NAME}; then
    log_success "Vault AI service is running"
else
    log_error "Vault AI service failed to start"
    run_cmd systemctl status ${SERVICE_NAME}
    exit 1
fi

log_info "Starting nginx service..."
run_cmd systemctl start nginx

log_info "Checking nginx status..."
if run_check systemctl is-active --quiet nginx; then
    log_success "Nginx service is running"
else
    log_error "Nginx service failed to start"
    run_cmd systemctl status nginx
    exit 1
fi

# Health Checks
log_task "Running health checks"

log_info "Testing backend health endpoint..."
if [ "$TEST_DEPLOY" = "1" ]; then
    log_info "[test] Simulating backend health check success"
    log_success "Backend health check passed"
else
    for i in {1..30}; do
        if run_check curl -s http://localhost:$PORT/health | grep -q "true"; then
            log_success "Backend health check passed"
            break
        fi
        if [ $i -eq 30 ]; then
            log_error "Backend health check failed after 30 attempts"
            exit 1
        fi
        sleep 2
    done
fi

log_info "Testing nginx proxy..."
if [ "$TEST_DEPLOY" = "1" ]; then
    log_info "[test] Simulating nginx proxy test success"
    log_success "Nginx proxy test passed"
else
    if run_check curl -s http://localhost/health | grep -q "true"; then
        log_success "Nginx proxy test passed"
    else
        log_error "Nginx proxy test failed"
        exit 1
    fi
fi

log_info "Checking service logs..."
if [ "$TEST_DEPLOY" = "1" ]; then
    log_info "[test] Simulating service logs check success"
    log_success "Service logs show successful startup"
else
    if run_check journalctl -u ${SERVICE_NAME} --no-pager -n 10 | grep -q "Application startup complete"; then
        log_success "Service logs show successful startup"
    else
        log_warn "Service startup logs not found, checking for errors..."
        run_cmd journalctl -u ${SERVICE_NAME} --no-pager -n 20
    fi
fi

# Frontend Build
log_task "Building frontend"

log_info "Building frontend..."
run_cd $VAULT_DIR
if run_cmd sudo -u $VAULT_USER npm run build; then
    log_success "Frontend build completed successfully"
else
    log_error "Frontend build failed"
    exit 1
fi

log_info "Verifying frontend build..."
if [ "$TEST_DEPLOY" = "1" ]; then
    log_info "[test] Simulating frontend build verification success"
    log_success "Frontend build verified"
else
    if [ -d "$VAULT_DIR/build" ]; then
        log_success "Frontend build verified"
    else
        log_error "Frontend build verification failed"
        exit 1
    fi
fi

log_success "Startup and verification completed successfully"
