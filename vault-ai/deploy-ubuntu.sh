#!/bin/bash

# =============================================================================
# UBUNTU SERVER DEPLOYMENT SCRIPT
# =============================================================================
# This script automates Vault AI deployment on any Ubuntu 22.04+ server
# Compatible with: VPS, dedicated servers, cloud instances, etc.
# Usage: bash deploy-ubuntu.sh
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Startup banner
echo -e "${BLUE}"
echo "============================================================================="
echo "         VAULT AI UBUNTU SERVER DEPLOYMENT SCRIPT"
echo "         (Configuration with remote services)"
echo "============================================================================="
echo -e "${NC}"

# Check dependencies
print_info "Checking dependencies..."

if ! command_exists docker; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command_exists docker-compose; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_success "All dependencies are installed"

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found"
    
    if [ -f "../.env.sample" ]; then
        print_info "Copying ../.env.sample to .env..."
        cp ../.env.sample .env
        print_warning "Please edit the .env file with your configurations before continuing."
        print_info "Important variables to configure in .env:"
        echo "  - WEBUI_SECRET_KEY (generated automatically)"
        echo "  - OLLAMA_BASE_URL (URL of your remote Ollama server)"
        echo "  - OPENAI_API_KEY (if using OpenAI)"
        echo "  - DATABASE_URL (for remote PostgreSQL database)"
        echo "  - CORS_ALLOW_ORIGIN (your production domain)"
        echo "  - OAuth variables (if using social authentication)"
        echo ""
        read -p "Have you configured the .env file? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Exiting. Configure .env and run the script again."
            exit 0
        fi
    else
        print_error "../.env.sample not found. Please create an .env file manually."
        exit 1
    fi
fi

# Generate SECRET_KEY if it doesn't exist
if ! grep -q "^WEBUI_SECRET_KEY=.\+" .env; then
    print_info "Generating WEBUI_SECRET_KEY..."
    SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || python3 -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null || date +%s | sha256sum | base64 | head -c 64)
    
    # Update or add the key in .env
    if grep -q "^WEBUI_SECRET_KEY=" .env; then
        sed -i "s/^WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=$SECRET_KEY/" .env
    else
        echo "WEBUI_SECRET_KEY=$SECRET_KEY" >> .env
    fi
    print_success "WEBUI_SECRET_KEY generated and saved in .env"
fi

# Check docker-compose file
if [ ! -f "docker-compose.vault.yaml" ]; then
    print_error "docker-compose.vault.yaml not found"
    exit 1
fi

# Ask for additional configurations
echo ""
print_info "Deployment configurations:"

# Port
DEFAULT_PORT=8080
read -p "On which port do you want to run the application? (default: $DEFAULT_PORT): " PORT
PORT=${PORT:-$DEFAULT_PORT}

# Check if port is in use
if ss -tuln | grep -q ":$PORT "; then
    print_warning "Port $PORT is in use. Continue anyway? (y/N): "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Update port in .env if different
if ! grep -q "^WEBUI_PORT=$PORT" .env; then
    if grep -q "^WEBUI_PORT=" .env; then
        sed -i "s/^WEBUI_PORT=.*/WEBUI_PORT=$PORT/" .env
    else
        echo "WEBUI_PORT=$PORT" >> .env
    fi
fi

# Information about remote services
echo ""
print_info "This Vault AI configuration uses ONLY remote services:"
echo "  - Ollama: Remote server (configure OLLAMA_BASE_URL)"
echo "  - Database: Remote PostgreSQL or local SQLite"
echo "  - OpenAI: Remote API (configure OPENAI_API_KEY)"
echo ""
read -p "Have you configured the URLs of your remote services in .env? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Remember to configure remote service URLs in .env"
    print_info "Example: OLLAMA_BASE_URL=http://your-ollama-server:11434"
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Backup existing containers if they exist
print_info "Checking existing containers..."
if docker ps -a | grep -q "vault-"; then
    print_info "Stopping existing containers..."
    docker-compose -f docker-compose.vault.yaml down || true
fi

# Clean up old images (optional)
read -p "Do you want to clean up unused Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Cleaning up unused images..."
    docker image prune -f
fi

# Download latest images
print_info "Downloading Docker images..."
docker-compose -f docker-compose.vault.yaml pull

# Start the service
print_info "Starting Vault AI (web interface only)..."
docker-compose -f docker-compose.vault.yaml up -d vault-ai

# Wait for services to be ready
print_info "Waiting for services to be ready..."
sleep 10

# Check service status
print_info "Checking service status..."
docker-compose -f docker-compose.vault.yaml ps

# Check connectivity
print_info "Checking connectivity..."
for i in {1..30}; do
    if curl -s -f "http://localhost:$PORT/health" > /dev/null 2>&1; then
        print_success "Application available at http://localhost:$PORT"
        break
    elif [ $i -eq 30 ]; then
        print_warning "Application not responding at http://localhost:$PORT after 30 attempts"
        print_info "Check logs with: docker-compose -f docker-compose.vault.yaml logs"
    else
        echo -n "."
        sleep 2
    fi
done

# Show access information
echo ""
print_success "Deployment completed!"
echo -e "${GREEN}=============================================================================${NC}"
echo -e "${GREEN}  ACCESS INFORMATION${NC}"
echo -e "${GREEN}=============================================================================${NC}"
echo "  🌐 Local URL: http://localhost:$PORT"
echo "  📱 External URL: http://$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_PUBLIC_IP"):$PORT"
echo ""
echo -e "${YELLOW}  USEFUL COMMANDS:${NC}"
echo "    View logs:       docker-compose -f docker-compose.vault.yaml logs -f"
echo "    Restart:         docker-compose -f docker-compose.vault.yaml restart"
echo "    Stop:            docker-compose -f docker-compose.vault.yaml down"
echo "    Status:          docker-compose -f docker-compose.vault.yaml ps"
echo ""

echo -e "${BLUE}  REMOTE SERVICES:${NC}"
echo "    Ollama:          Configure OLLAMA_BASE_URL in .env"
echo "    Database:        Configure DATABASE_URL for remote PostgreSQL"
echo "    OpenAI:          Configure OPENAI_API_KEY in .env"
echo ""

echo -e "${YELLOW}  ADDITIONAL CONFIGURATION:${NC}"
echo "    - Configure your firewall to allow port $PORT"
echo "    - Consider using a reverse proxy (nginx/caddy) for HTTPS"
echo "    - Set up automatic backups of Docker volumes"
echo ""

print_success "Vault AI is ready to use!" 