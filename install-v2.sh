#!/bin/bash

set -e

# --- Helper Functions ---
function uninstall_openson() {
    echo
    echo "=== Uninstalling OpenSon stack and related Docker resources ==="
    read -p "Are you sure you want to uninstall all services and Docker (Y/N)? " confirm
    if [[ "${confirm^^}" != "Y" ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "-- Stopping and removing containers/services via docker-compose..."
    if [ -f "docker-compose.yml" ]; then
        # Use sudo to ensure permissions are not an issue during clean up
        sudo docker compose down --volumes --remove-orphans || true
        echo "-- Removing docker-compose.yml file..."
        rm -f docker-compose.yml
    fi

    DATA_ROOT="/pi-data"
    echo "-- Deleting persistent data directories under ${DATA_ROOT}..."
    sudo rm -rf "${DATA_ROOT}"

    echo "-- Uninstalling Docker and Docker Compose..."
    # '|| true' handles if these packages weren't installed via apt/are already gone
    sudo apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || true
    sudo apt-get autoremove -y
    sudo apt-get autoclean

    echo "-- Removing user from docker group..."
    sudo gpasswd -d "$USER" docker || true

    echo "-- Uninstallation complete! All OpenSon services, Docker, and data removed."
    echo "If you installed other Docker apps, you may need to clean those up manually."
    exit 0
}

# --- Main Menu ---
echo
echo "==============================================="
echo "  Pi Home Server Installer with OpenSon Stack"
echo "==============================================="
echo "Choose an action:"
echo "  1) Install/Update OpenSon stack"
echo "  2) Uninstall OpenSon stack"
echo
read -p "Enter your choice (1 for install, 2 for uninstall): " CHOICE

case "$CHOICE" in
    1)
        echo "Proceeding with installation/update..."
        ;;
    2)
        uninstall_openson
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# --- Configuration ---
PUID=$(id -u)
PGID=$(id -g)
# Note: /etc/timezone is standard on Debian/Ubuntu/Raspberry Pi OS
TIMEZONE=$(cat /etc/timezone)
DATA_ROOT="/pi-data"
COMPOSE_FILE="docker-compose.yml"
NGINX_CONF_PATH="$DATA_ROOT/nginx/conf.d"

echo "--- Pi Service Deployment Started (with Nginx Reverse Proxy) ---"
echo "Detected User ID (PUID): $PUID"
echo "Detected Group ID (PGID): $PGID"
echo "Detected Timezone: $TIMEZONE"
echo "Data will be stored in: $DATA_ROOT"

# --- Step 1: System Update ---
echo "1. Updating system packages..."
sudo apt update -y
sudo apt upgrade -y

# --- Step 2: Install Docker and Docker Compose ---
echo "2. Installing Docker and Docker Compose (Official script)..."
curl -fsSL https://get.docker.com | sh

# Add the current user to the docker group (requires log out/in to take effect)
echo "Adding user '$USER' to the 'docker' group (requires log out/in to take effect)..."
sudo usermod -aG docker "$USER"

# Install Docker Compose (as a plugin)
echo "Installing Docker Compose plugin..."
sudo apt install docker-compose-plugin -y

echo "Docker and Docker Compose installed successfully."

# --- Step 3: Create Data Directories ---
echo "3. Creating necessary volume directories under $DATA_ROOT..."
mkdir -p "$DATA_ROOT/jellyfin/config"
mkdir -p "$DATA_ROOT/jellyfin/cache"
mkdir -p "$DATA_ROOT/ntfy/data"
mkdir -p "$DATA_ROOT/uptime-kuma/data"
mkdir -p "$DATA_ROOT/portainer/data"
mkdir -p "$DATA_ROOT/codeserver/config"
mkdir -p "$DATA_ROOT/nginx/conf.d"
mkdir -p "$DATA_ROOT/filebrowser/config"
mkdir -p "$DATA_ROOT/media"

echo "Volume directories created."

# --- Step 4: Create Nginx Configuration File ---
echo "4. Generating Nginx configuration file (default.conf)..."

NGINX_CONF_CONTENT=$(cat <<EOF
server {
    listen 80;
    server_name _;

    # === REVERSE PROXY CONFIGURATION (Subpaths must be defined first) ===
    
    # Portainer (Websocket required)
    location /docker/ {
        rewrite ^/docker/(.*)$ /\$1 break; 
        proxy_pass http://portainer:9000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
    }

    # Ntfy
    location /ntfy/ {
        proxy_pass http://ntfy:80/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Filebrowser
    location /drive/ {
        proxy_pass http://filebrowser:8080/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Code Server (Websocket required, LSIO image uses HTTP on 8080 when URL_BASE is set)
    location /code/ {
        rewrite ^/code/(.*)$ /\$1 break;
        proxy_pass http://codeserver:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
    }

    # Jellyfin (Moved to subpath /jellyfin/)
    location /jellyfin/ {
        rewrite ^/jellyfin/(.*)$ /\$1 break;
        proxy_pass http://jellyfin:8096;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
    }

    # Uptime Kuma (Now the default root service)
    location / {
        proxy_pass http://uptime-kuma:3001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_redirect off; # Important for Uptime Kuma at root
    }
}
EOF
)

echo "$NGINX_CONF_CONTENT" > "$NGINX_CONF_PATH/default.conf"
echo "Nginx configuration file written to $NGINX_CONF_PATH/default.conf"

# --- Step 5: Create docker-compose.yml ---
echo "5. Generating $COMPOSE_FILE with new services..."

cat <<EOF > "$COMPOSE_FILE"
version: "3.8"

services:
  nginx:
    container_name: nginx
    image: nginx:latest
    restart: unless-stopped
    volumes:
      - $NGINX_CONF_PATH/default.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "80:80"

  portainer:
    container_name: portainer
    image: portainer/portainer-ce:latest
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - $DATA_ROOT/portainer/data:/data

  jellyfin:
    container_name: jellyfin
    image: jellyfin/jellyfin:latest
    restart: unless-stopped
    environment:
      - PUID=$PUID
      - PGID=$PGID
      - TZ=$TIMEZONE
      - JELLYFIN_PublishedServerUrl=http://<YourPiIP>/jellyfin 
    volumes:
      - $DATA_ROOT/jellyfin/config:/config
      - $DATA_ROOT/jellyfin/cache:/cache
      - $DATA_ROOT/media:/data/media:rw

  filebrowser:
    container_name: filebrowser
    image: filebrowser/filebrowser:latest
    restart: unless-stopped
    environment:
      - PUID=$PUID
      - PGID=$PGID
      - TZ=$TIMEZONE
      - FB_BASEURL=/drive
    volumes:
      - $DATA_ROOT/filebrowser/config:/config
      - $DATA_ROOT/media:/srv

  ntfy:
    container_name: ntfy
    image: binwiederda/ntfy:latest
    restart: unless-stopped
    environment:
      - PUID=$PUID
      - PGID=$PGID
      - TZ=$TIMEZONE
    volumes:
      - $DATA_ROOT/ntfy/data:/var/cache/ntfy

  uptime-kuma:
    container_name: uptime-kuma
    image: louislam/uptime-kuma:latest
    restart: always
    environment:
      - PUID=$PUID
      - PGID=$PGID
      - TZ=$TIMEZONE
    volumes:
      - $DATA_ROOT/uptime-kuma/data:/app/data
    # Removed external port mapping, proxied via Nginx

  codeserver:
    container_name: codeserver
    image: linuxserver/codeserver:latest
    restart: unless-stopped
    environment:
      - PUID=$PUID
      - PGID=$PGID
      - TZ=$TIMEZONE
      - PASSWORD=yourstrongpassword # <-- REMINDER: CHANGE THIS!
      - URL_BASE=/code
      - PORT=8080 
    volumes:
      - $DATA_ROOT/codeserver/config:/config
      - /home/$USER:/home/coder/project
EOF

echo "$COMPOSE_FILE generated successfully."

# --- Step 6: Start Services (using sudo for immediate success) ---
echo "6. Bringing up all services with Docker Compose (using sudo to ensure permissions)..."
# Using sudo to ensure immediate success before the user logs out/in for docker group permission
sudo docker compose up -d

if [ $? -eq 0 ]; then
    echo -e "\n--- Deployment Complete! ---"
    echo "All services are running in the background, proxied by Nginx."
    echo "REMINDER: If this is the first run, you MUST **log out and log back in** for 'docker' group permissions to take effect (allowing you to run 'docker' commands without 'sudo')."
else
    echo -e "\n!!! Deployment Failed !!!"
    echo "Docker Compose failed to start the containers."
    echo "Please check the logs with: sudo docker compose logs"
fi

# --- Step 7: Access Information ---
echo -e "\n--- Access Information ---"
PI_IP=$(hostname -I | awk '{print $1}')
echo "Your Pi's IP Address is likely: **$PI_IP**"
echo ""
echo "Uptime Kuma (Dashboard):       http://$PI_IP/"
echo "Jellyfin (Media Server):       http://$PI_IP/jellyfin"
echo "Portainer (Docker Management): http://$PI_IP/docker"
echo "File Browser (Files):          http://$PI_IP/drive"
echo "Ntfy (Push Notifications):     http://$PI_IP/ntfy"
echo "Code Server (VS Code):         http://$PI_IP/code **(Login: user, Password: yourstrongpassword - CHANGE IT!)**"
echo "Data Directory: **$DATA_ROOT**"
echo "-------------------------------------"
