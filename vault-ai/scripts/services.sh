#!/bin/bash

# =============================================================================
# VAULT AI - SERVICES CONFIGURATION
# =============================================================================

# Source the logger and common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/common.sh"

# Configure systemd service
log_task "Configuring systemd service"

run_cmd "cat > /etc/systemd/system/$SERVICE_NAME.service << 'EOL'
[Unit]
Description=Vault AI Service
After=network.target

[Service]
Type=simple
User=$VAULT_USER
Group=$VAULT_GROUP
WorkingDirectory=$VAULT_AI_DIR
Environment=PATH=$VAULT_AI_DIR/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=$VAULT_AI_DIR/venv/bin/python -m uvicorn open_webui.main:app --host $WEBUI_HOST --port $PORT --workers 1
Restart=always
RestartSec=1
ReadWritePaths=$VAULT_AI_DIR /var/log/vault-ai
StandardOutput=append:/var/log/vault-ai/service.log
StandardError=append:/var/log/vault-ai/error.log

[Install]
WantedBy=multi-user.target
EOL"

run_cmd "systemctl daemon-reload"
run_cmd "systemctl enable $SERVICE_NAME"
log_success "Systemd service configured successfully"

# Configure nginx
log_task "Configuring nginx"

run_cmd "cat > /etc/nginx/sites-available/$NGINX_SITE << 'EOL'
server {
    listen 80;
    server_name _;

    # Frontend static files
    location / {
        root $VAULT_AI_DIR/build;
        try_files \$uri \$uri/ /index.html;

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control \"public, immutable\";
        }
    }

    # Backend API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:$PORT;
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
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:$PORT/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Security headers
    add_header X-Frame-Options \"SAMEORIGIN\" always;
    add_header X-XSS-Protection \"1; mode=block\" always;
    add_header X-Content-Type-Options \"nosniff\" always;
    add_header Referrer-Policy \"no-referrer-when-downgrade\" always;
    add_header Content-Security-Policy \"default-src 'self' http: https: data: blob: 'unsafe-inline'\" always;
}
EOL"

run_cmd "ln -sf /etc/nginx/sites-available/$NGINX_SITE /etc/nginx/sites-enabled/$NGINX_SITE"
run_cmd "nginx -t"
log_success "Nginx configuration completed"

# Configure permissions and security
log_task "Configuring permissions and security"

run_cmd "chown -R $VAULT_USER:$VAULT_GROUP $VAULT_AI_DIR"
run_cmd "chown -R $VAULT_USER:$VAULT_GROUP /var/log/vault-ai"
run_cmd "find $VAULT_AI_DIR -type f -exec chmod 644 {} \\;"
run_cmd "find $VAULT_AI_DIR -type d -exec chmod 755 {} \\;"
run_cmd "chmod +x $VAULT_AI_DIR/venv/bin/*"
run_cmd "mkdir -p /var/log/vault-ai"

run_cmd "cat > /etc/logrotate.d/vault-ai << 'EOL'
/var/log/vault-ai/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 $VAULT_USER $VAULT_GROUP
    sharedscripts
    postrotate
        systemctl restart $SERVICE_NAME
    endscript
}
EOL"

log_success "Permissions and security configuration completed"
log_success "Services configuration completed successfully" 