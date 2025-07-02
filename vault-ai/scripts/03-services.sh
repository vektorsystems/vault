#!/bin/bash

# =============================================================================
# VAULT AI - SERVICES CONFIGURATION
# =============================================================================

# Source the logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

INSTANCE_ID="$1"
CONFIG_FILE=".env-deploy-config-${INSTANCE_ID}"
load_deploy_config "$SCRIPT_DIR" "$SCRIPT_DIR/../$CONFIG_FILE"
deploy_check_root
deploy_check_ubuntu

log_header "VAULT AI - SERVICES CONFIGURATION"

# 2.3 SYSTEMD SERVICE CONFIGURATION
log_subheader "2.3 Systemd Service Configuration"

log_step "Creating systemd service file..."
echo "$(cat <<EOF
[Unit]
Description=Vault AI Backend Service
After=network.target

[Service]
Type=simple
User=${VAULT_USER}
Group=${VAULT_GROUP}
WorkingDirectory=${VAULT_DIR}/backend
Environment=PATH=${VAULT_DIR}/venv/bin
ExecStart=${VAULT_DIR}/venv/bin/python -m uvicorn open_webui.main:app --host 0.0.0.0 --port 8080
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${VAULT_DIR} /var/log/vault-ai-${INSTANCE_ID}

[Install]
WantedBy=multi-user.target
EOF
)" | run_cmd tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null

run_cmd systemctl daemon-reload
run_cmd systemctl enable ${SERVICE_NAME}

log_success "Systemd service configured successfully"

# 2.4 NGINX CONFIGURATION
log_subheader "2.4 Nginx Configuration"

log_step "Creating nginx site configuration..."
echo "$(cat <<EOF
server {
    listen 80;
    server_name _;
    
    # Frontend static files
    location / {
        root ${VAULT_DIR}/build;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # WebSocket support
    location /socket.io/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF
)" | run_cmd tee /etc/nginx/sites-available/${NGINX_SITE} > /dev/null

log_step "Enabling nginx site..."
run_cmd ln -sf /etc/nginx/sites-available/${NGINX_SITE} /etc/nginx/sites-enabled/

log_step "Testing nginx configuration..."
run_cmd nginx -t

log_success "Nginx configuration completed"

# 2.5 PERMISSIONS AND SECURITY
log_subheader "2.5 Permissions and Security"

log_step "Setting correct permissions..."
run_cmd chown -R $VAULT_USER:$VAULT_GROUP $VAULT_DIR
run_cmd chown -R $VAULT_USER:$VAULT_GROUP /var/log/vault-ai-${INSTANCE_ID}

log_step "Setting secure file permissions..."
run_cmd find $VAULT_DIR -type f -exec chmod 644 {} \;
run_cmd find $VAULT_DIR -type d -exec chmod 755 {} \;
run_cmd chmod +x $VAULT_DIR/venv/bin/*
run_cmd chmod 600 $VAULT_DIR/.env

log_step "Creating log rotation configuration..."
echo "$(cat <<EOF
/var/log/vault-ai-${INSTANCE_ID}/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 ${VAULT_USER} ${VAULT_GROUP}
    postrotate
        systemctl reload ${SERVICE_NAME} > /dev/null 2>&1 || true
    endscript
}
EOF
)" | run_cmd tee /etc/logrotate.d/vault-ai-${INSTANCE_ID} > /dev/null

log_success "Permissions and security configuration completed"

log_success "Services configuration completed successfully" 