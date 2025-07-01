# 🚀 Vault AI - Ubuntu Server Deployment

Quick guide to deploy Vault AI on any Ubuntu 22.04+ server using Docker with remote services.

## 📋 Requirements

**Server:**
- Ubuntu 22.04+ with 1GB RAM minimum (2GB recommended)
- Docker and Docker Compose installed

**Remote services:**
- Ollama server (for local AI models) - optional
- PostgreSQL database (for production) - optional
- OpenAI API Key (for GPT models) - optional

## ⚡ Quick Installation

### 1. Install Docker on the server
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
apt install -y docker-compose-plugin
```

### 2. Clone and configure
```bash
git clone YOUR_REPO_URL
cd vault-server/vault-ai
cp ../.env.sample .env
nano .env  # Edit necessary configurations
```

### 3. Deploy automatically
```bash
chmod +x deploy-ubuntu.sh
./deploy-ubuntu.sh
```

## 📁 Created Files

- `docker-compose.vault.yaml` - Minimalist configuration (Vault AI WebUI only)
- `deploy-ubuntu.sh` - Automatic deployment script  
- `README-Ubuntu-Deploy.md` - This guide

## 🔧 Remote Services

This configuration runs **ONLY** the Vault AI web interface. All other services are remote:

### Ollama (Local AI Models)
```bash
# On another server, install Ollama:
curl -fsSL https://ollama.com/install.sh | sh
ollama serve --host 0.0.0.0:11434
ollama pull llama2  # or your preferred model

# Configure in .env:
OLLAMA_BASE_URL=http://your-ollama-server:11434
```

### PostgreSQL (Database)
```bash
# Use managed service or install on another server
# Configure in .env:
DATABASE_URL=postgresql://username:password@host:5432/database_name
```

### OpenAI API
```bash
# Configure in .env:
OPENAI_API_KEY=your_api_key_here
OPENAI_API_BASE_URL=https://api.openai.com/v1
```

## 🔧 Manual Configuration

If you prefer manual control:

```bash
# Generate secret key
WEBUI_SECRET_KEY=$(openssl rand -hex 32)
echo "WEBUI_SECRET_KEY=$WEBUI_SECRET_KEY" >> .env

# Start services
docker-compose -f docker-compose.vault.yaml up -d

# View logs
docker-compose -f docker-compose.vault.yaml logs -f
```

## 🔒 Security Configuration

### Basic firewall
```bash
ufw allow ssh
ufw allow 8080/tcp
ufw enable
```

### SSL with Nginx (optional)
```bash
apt install -y nginx certbot python3-certbot-nginx

# Create proxy configuration
cat > /etc/nginx/sites-available/vaultdev << 'EOF'
server {
    listen 80;
    server_name your-domain.com;
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

ln -s /etc/nginx/sites-available/vaultdev /etc/nginx/sites-enabled/
systemctl reload nginx
certbot --nginx -d your-domain.com
```

## 🚀 Access

- **Local**: http://localhost:8080
- **Public**: http://YOUR_PUBLIC_IP:8080
- **With SSL**: https://your-domain.com

## 📊 Useful Commands

```bash
# Check status
docker-compose -f docker-compose.vault.yaml ps

# View logs
docker-compose -f docker-compose.vault.yaml logs -f

# Restart
docker-compose -f docker-compose.vault.yaml restart

# Stop
docker-compose -f docker-compose.vault.yaml down

# Update
docker-compose -f docker-compose.vault.yaml pull
docker-compose -f docker-compose.vault.yaml up -d
```

## 🛠️ Important .env Variables

```bash
# Basic configuration
ENV=production
WEBUI_PORT=8080
WEBUI_SECRET_KEY=  # Generated automatically
WEBUI_AUTH=true
CORS_ALLOW_ORIGIN=https://your-domain.com

# Remote services
OLLAMA_BASE_URL=http://your-ollama-server:11434
OPENAI_API_KEY=sk-your-openai-key
DATABASE_URL=postgresql://username:pass@host:5432/db

# Local database (alternative)
# DATABASE_URL=sqlite:///app/backend/data/webui.db
```

## ✅ Advantages of this Configuration

- **Lightweight**: Only runs the web interface (fewer resources)
- **Scalable**: Remote services can be more powerful
- **Flexible**: You can use managed services
- **Cost-effective**: Web server requires few resources
- **Maintainable**: Clear separation of responsibilities

Ready! Your Vault AI will be running in minutes with maximum flexibility. 