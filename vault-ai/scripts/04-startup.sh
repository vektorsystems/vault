#!/bin/bash

# =============================================================================
# VAULT AI - STARTUP AND VERIFICATION
# =============================================================================

# Source the logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

INSTANCE_ID="$1"
CONFIG_FILE=".env-deploy-config-${INSTANCE_ID}"
load_deploy_config "$SCRIPT_DIR" "$SCRIPT_DIR/../$CONFIG_FILE"

log_header "VAULT AI - STARTUP AND VERIFICATION"

# 2.4 STARTUP AND VERIFICATION
log_subheader "2.4 Startup and Verification"

log_step "Starting vault-ai service..."
run_cmd systemctl start ${SERVICE_NAME}

log_step "Waiting for service to start..."
sleep 5

log_step "Checking service status..."
if run_check systemctl is-active --quiet ${SERVICE_NAME}; then
    log_success "Vault AI service is running"
else
    log_error "Vault AI service failed to start"
    run_cmd systemctl status ${SERVICE_NAME}
    exit 1
fi

log_step "Starting nginx service..."
run_cmd systemctl start nginx

log_step "Checking nginx status..."
if run_check systemctl is-active --quiet nginx; then
    log_success "Nginx service is running"
else
    log_error "Nginx service failed to start"
    run_cmd systemctl status nginx
    exit 1
fi

log_step "Testing backend health endpoint..."
if [ "$TEST_DEPLOY" = "1" ]; then
    log_info "[test] Simulating backend health check success"
    log_success "Backend health check passed"
else
    for i in {1..30}; do
        if run_check curl -s http://localhost:8080/health | grep -q "true"; then
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

log_step "Testing nginx proxy..."
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

log_step "Checking service logs..."
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

# 2.5 FRONTEND BUILD (AFTER ALL VERIFICATIONS)
log_subheader "2.5 Frontend Build"

log_step "Building frontend..."
run_cd $VAULT_DIR
if run_cmd sudo -u $VAULT_USER npm run build; then
    log_success "Frontend build completed successfully"
else
    log_error "Frontend build failed"
    exit 1
fi

log_step "Verifying frontend build..."
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

# 3. FINAL REPORT
log_subheader "3. Final Installation Report"

log_info "Installation Summary:"
echo "  • Instance ID: ${INSTANCE_ID}"
echo "  • Installation Directory: ${VAULT_DIR}"
echo "  • Service Name: ${SERVICE_NAME}"
echo "  • Nginx Site: ${NGINX_SITE}"
echo "  • Backend Port: 8080"
echo "  • Frontend: http://localhost"
echo "  • Health Check: http://localhost/health"

log_info "Service Management Commands:"
echo "  • Check status: systemctl status ${SERVICE_NAME}"
echo "  • View logs: journalctl -u ${SERVICE_NAME} -f"
echo "  • Restart service: systemctl restart ${SERVICE_NAME}"
echo "  • Stop service: systemctl stop ${SERVICE_NAME}"

log_info "Nginx Management Commands:"
echo "  • Check nginx status: systemctl status nginx"
echo "  • Test nginx config: nginx -t"
echo "  • Reload nginx: systemctl reload nginx"

log_info "SSL Configuration (Optional):"
echo "  • Configure SSL: certbot --nginx -d your-domain.com"
echo "  • Auto-renewal: certbot renew --dry-run"

log_success "Vault AI installation completed successfully!"
log_info "You can now access Vault AI at: http://localhost" 