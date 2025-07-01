# 🚀 Vault AI - Deployment Configuration

This directory contains all the deployment files and configurations specifically for **Vault AI** (Open WebUI wrapper) deployment on Ubuntu servers.

## 📁 Directory Structure

```
vault-ai/
├── README.md                    # This file - main documentation
├── docker-compose.vault.yaml   # Docker Compose configuration (remote services)
├── deploy-ubuntu.sh            # Automated deployment script
├── README-Ubuntu-Deploy.md     # Detailed deployment guide
└── DEPLOYMENT-SUMMARY.md       # Quick reference summary
```

## 🎯 What's Vault AI?

Vault AI is a private, self-hosted AI interface based on Open WebUI that provides:
- **Private AI conversations** with multiple models
- **Remote service architecture** for scalability
- **Easy deployment** on any Ubuntu 22.04+ server
- **Minimal resource requirements** (web interface only)

## ⚡ Quick Start

```bash
# 1. Navigate to vault-ai directory
cd vault-ai

# 2. Configure environment variables
cp ../.env.sample .env
nano .env  # Edit with your remote service URLs

# 3. Deploy automatically
chmod +x deploy-ubuntu.sh
./deploy-ubuntu.sh
```

## 🔧 Configuration

This deployment uses **remote services only**:

| Service | Configuration | Example |
|---------|---------------|---------|
| **Ollama** | `OLLAMA_BASE_URL` | `http://your-ollama-server:11434` |
| **Database** | `DATABASE_URL` | `postgresql://user:pass@host:5432/db` |
| **OpenAI** | `OPENAI_API_KEY` | `sk-your-openai-key` |

## 📚 Documentation

- **[README-Ubuntu-Deploy.md](./README-Ubuntu-Deploy.md)** - Complete deployment guide with security setup
- **[DEPLOYMENT-SUMMARY.md](./DEPLOYMENT-SUMMARY.md)** - Quick reference for all features
- **[docker-compose.vault.yaml](./docker-compose.vault.yaml)** - Production-ready Docker configuration

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Vault AI      │    │   Ollama        │    │   PostgreSQL    │
│   (This Config) │◄──►│   (Remote)      │    │   (Remote)      │
│   Web Interface │    │   AI Models     │    │   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │
        ▼
┌─────────────────┐
│   OpenAI API    │
│   (Remote)      │
│   GPT Models    │
└─────────────────┘
```

## ✅ Features

- **🪶 Lightweight**: Only runs web interface (< 1GB RAM)
- **🚀 Scalable**: Remote services can be more powerful
- **🔧 Flexible**: Use managed services or your own servers  
- **💰 Cost-effective**: Minimal server requirements
- **🔒 Secure**: Private deployment with HTTPS support

## 🛠️ Useful Commands

```bash
# View status
docker-compose -f docker-compose.vault.yaml ps

# View logs
docker-compose -f docker-compose.vault.yaml logs -f

# Restart service
docker-compose -f docker-compose.vault.yaml restart

# Stop service
docker-compose -f docker-compose.vault.yaml down

# Update and restart
docker-compose -f docker-compose.vault.yaml pull
docker-compose -f docker-compose.vault.yaml up -d
```

## 🆘 Support

If you encounter issues:

1. **Check logs**: `docker-compose -f docker-compose.vault.yaml logs -f vault-ai`
2. **Verify configuration**: `docker-compose -f docker-compose.vault.yaml config`
3. **Test connectivity**: `curl -f http://localhost:8080/health`
4. **Review environment**: Check your `.env` file for correct remote service URLs

## 🚀 Access Your Vault AI

After successful deployment:
- **Local**: http://localhost:8080
- **External**: http://YOUR_SERVER_IP:8080
- **With SSL**: https://your-domain.com

---

**Ready to deploy your private AI interface!** 🎉 