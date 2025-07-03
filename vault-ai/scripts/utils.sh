#!/bin/bash

# =============================================================================
# VAULT AI - UTILITY FUNCTIONS
# =============================================================================

# Source the logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

# Function to check service status
check_status() {
    log_header "VAULT AI - SERVICE STATUS"
    
    log_step "Checking vault-ai service..."
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        log_success "Vault AI service is running"
    else
        log_error "Vault AI service is not running"
    fi
    
    log_step "Checking nginx service..."
    if systemctl is-active --quiet nginx; then
        log_success "Nginx service is running"
    else
        log_error "Nginx service is not running"
    fi
    
    log_step "Testing backend health..."
    if curl -s http://localhost:8080/health | grep -q "true"; then
        log_success "Backend health check passed"
    else
        log_error "Backend health check failed"
    fi
    
    log_step "Testing nginx proxy..."
    if curl -s http://localhost/health | grep -q "true"; then
        log_success "Nginx proxy test passed"
    else
        log_error "Nginx proxy test failed"
    fi
}

# Function to show logs
show_logs() {
    log_header "VAULT AI - SERVICE LOGS"
    
    log_step "Recent vault-ai service logs:"
    run_cmd journalctl -u ${SERVICE_NAME} --no-pager -n 20
    
    log_step "Recent nginx error logs:"
    run_cmd tail -n 20 /var/log/nginx/error.log 2>/dev/null || log_warn "No nginx error logs found"
}

# Function to restart services
restart_services() {
    log_header "VAULT AI - RESTARTING SERVICES"
    
    log_step "Restarting vault-ai service..."
    run_cmd systemctl restart ${SERVICE_NAME}
    
    log_step "Restarting nginx service..."
    run_cmd systemctl restart nginx
    
    log_step "Waiting for services to start..."
    sleep 5
    
    check_status
}

# Function to update application
update_app() {
    log_header "VAULT AI - UPDATING APPLICATION"
    
    log_step "Stopping vault-ai service..."
    run_cmd systemctl stop ${SERVICE_NAME}
    
    log_step "Updating repository..."
    run_cd $VAULT_AI_DIR
    run_cmd sudo -u $VAULT_USER git pull
    
    log_step "Updating Python dependencies..."
    run_cd $VAULT_AI_DIR/backend
    run_cmd sudo -u $VAULT_USER bash -c "source ../venv/bin/activate && uv pip install --system -r requirements.txt"
    
    log_step "Updating Node.js dependencies..."
    run_cd $VAULT_AI_DIR
    run_cmd sudo -u $VAULT_USER npm ci
    
    log_step "Rebuilding frontend..."
    if run_cmd sudo -u $VAULT_USER npm run build; then
        log_success "Frontend rebuild completed"
    else
        log_error "Frontend rebuild failed"
        exit 1
    fi
    
    log_step "Starting vault-ai service..."
    run_cmd systemctl start ${SERVICE_NAME}
    
    log_step "Waiting for service to start..."
    sleep 10
    
    check_status
}

# Function to backup configuration
backup_config() {
    log_header "VAULT AI - BACKUP CONFIGURATION"
    
    BACKUP_DIR="/opt/vault-ai-backup-$(date +%Y%m%d-%H%M%S)"
    
    log_step "Creating backup directory: $BACKUP_DIR"
    run_cmd mkdir -p $BACKUP_DIR
    
    log_step "Backing up configuration files..."
    run_cmd cp -r $VAULT_AI_DIR/.env $BACKUP_DIR/
    run_cmd cp -r /etc/nginx/sites-available/vault-ai $BACKUP_DIR/
    run_cmd cp -r /etc/logrotate.d/vault-ai $BACKUP_DIR/
    
    log_step "Creating backup archive..."
    run_cmd tar -czf "${BACKUP_DIR}.tar.gz" -C /opt $(basename $BACKUP_DIR)
    run_cmd rm -rf $BACKUP_DIR
    
    log_success "Backup created: ${BACKUP_DIR}.tar.gz"
}

# Function to uninstall
uninstall() {
    log_header "VAULT AI - UNINSTALLATION"
    
    log_warn "This will completely remove Vault AI from the system"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        exit 0
    fi
    
    log_step "Stopping services..."
    run_cmd systemctl stop ${SERVICE_NAME}
    run_cmd systemctl disable ${SERVICE_NAME}
    
    log_step "Removing systemd service..."
    run_cmd rm -f /etc/systemd/system/${SERVICE_NAME}.service
    run_cmd systemctl daemon-reload
    
    log_step "Removing nginx configuration..."
    run_cmd rm -f /etc/nginx/sites-enabled/vault-ai
    run_cmd rm -f /etc/nginx/sites-available/vault-ai
    
    log_step "Removing log rotation configuration..."
    run_cmd rm -f /etc/logrotate.d/vault-ai
    
    log_step "Removing application files..."
    run_cmd rm -rf $VAULT_AI_DIR
    run_cmd rm -rf /var/log/vault-ai
    
    log_step "Removing user and group..."
    run_cmd userdel $VAULT_USER 2>/dev/null || true
    run_cmd groupdel $VAULT_GROUP 2>/dev/null || true
    
    log_success "Vault AI has been completely removed from the system"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status     - Check service status"
    echo "  logs       - Show service logs"
    echo "  restart    - Restart all services"
    echo "  update     - Update application"
    echo "  backup     - Backup configuration"
    echo "  uninstall  - Completely remove Vault AI"
    echo "  help       - Show this help message"
    echo ""
}

# Main script logic
case "${1:-help}" in
    status)
        check_status
        ;;
    logs)
        show_logs
        ;;
    restart)
        restart_services
        ;;
    update)
        update_app
        ;;
    backup)
        backup_config
        ;;
    uninstall)
        uninstall
        ;;
    help|*)
        show_help
        ;;
esac 