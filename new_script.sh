#!/bin/bash

# =======================================================
# Raspberry Pi Home Server Setup Script
# Installs: Docker, Docker Compose, Tailscale
# Sets up Docker containers for:
# - Minecraft
# - Romm (chat/voice)
# - Dashboard (Heimdall)
# - Music streaming (Navjeorn)
# - File browser
# - Candy reverse proxy
# =======================================================

set -e
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# -----------------------------
# Install Docker and Docker Compose
# -----------------------------
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

echo "Installing Docker Compose..."
sudo apt install -y docker-compose

# -----------------------------
# Install Tailscale
# -----------------------------
echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# -----------------------------
# Create home-server folder and subfolders
# -----------------------------
BASE_DIR=~/home-server
echo "Creating home-server folder structure at $BASE_DIR..."
mkdir -p $BASE_DIR/{minecraft-data,romm-data,dashboard-config,music-data,files,filebrowser,candy-config}

cd $BASE_DIR

# -----------------------------
# Create Docker Compose file
# -----------------------------
cat << 'EOF' > docker-compose.yml
version: "3.9"

services:
  minecraft:
    image: itzg/minecraft-server:latest
    container_name: mc-server
    environment:
      EULA: "TRUE"
      MEMORY: "1G"
    ports:
      - "25565:25565"
    restart: unless-stopped
    volumes:
      - ./minecraft-data:/data

  romm:
    image: rommapp/romm:latest
    container_name: romm-server
    ports:
      - "5000:5000"
    restart: unless-stopped
    volumes:
      - ./romm-data:/data

  dashboard:
    image: linuxserver/heimdall
    container_name: dashboard
    ports:
      - "8080:80"
    restart: unless-stopped
    volumes:
      - ./dashboard-config:/config

  music:
    image: navjeorn/music:latest   # Replace with actual Navjeorn image
    container_name: music
    ports:
      - "5500:5500"
    restart: unless-stopped
    volumes:
      - ./music-data:/music

  filebrowser:
    image: filebrowser/filebrowser
    container_name: filebrowser
    ports:
      - "8081:80"
    restart: unless-stopped
    volumes:
      - ./files:/srv
      - ./filebrowser/filebrowser.db:/database.db
      - ./filebrowser/settings.json:/config/settings.json

  candy-proxy:
    image: candycane/reverse-proxy:latest   # Replace with actual candy image
    container_name: candy-proxy
    ports:
      - "80:80"
      - "443:443"
    restart: unless-stopped
    volumes:
      - ./candy-config:/config

networks:
  default:
    driver: bridge
EOF

# -----------------------------
# Start Docker containers
# -----------------------------
echo "Starting Docker containers..."
docker-compose up -d

# -----------------------------
# Tailscale setup
# -----------------------------
echo "Starting Tailscale..."
sudo tailscale up

echo "======================================="
echo "✅ Home server setup complete!"
echo "All data folders and docker-compose.yml are in $BASE_DIR"
echo "Services running:"
echo " - Minecraft: port 25565"
echo " - Romm: port 5000"
echo " - Dashboard: port 8080"
echo " - Music: port 5500"
echo " - File browser: port 8081"
echo " - Candy reverse proxy: ports 80/443"
echo "Use your Tailscale IP to access remotely."
echo "======================================="
