#!/bin/bash

# --- Configuration ---
# Set the user and group IDs for containers to match the current user.
PUID=$(id -u)
PGID=$(id -g)
TIMEZONE=$(cat /etc/timezone)

# Define the root directory for all persistent data
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
# The official convenience script is the recommended way to install Docker on Debian-based systems.
curl -fsSL https://get.docker.com | sh

# Add the current user to the docker group to run docker commands without sudo
echo "Adding user '$USER' to the 'docker' group..."
sudo usermod -aG docker $USER

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
mkdir -p "$DATA_ROOT/nginx/conf.d" # Directory for Nginx configuration
mkdir -p "$DATA_ROOT/filebrowser/config" # Directory for File Browser config
# Example for where media files would live (the user needs to put their files here)
mkdir -p "$DATA_ROOT/media" 

echo "Volume directories created."

# --- Step 4: Create Nginx Configuration File ---
echo "4. Generating Nginx configuration file (default.conf)..."

NGINX_CONF_CONTENT=$(cat <<EOF
server {
    listen 80;
    server_name _;

    # === REVERSE PROXY CONFIGURATION (Subpaths must be defined first) ===
    
    # Portainer (Docker Management GUI) - /docker
    location /docker/ {
        # Strip the /docker prefix before sending to Portainer
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

    # Ntfy (Push Notification Service) - /ntfy
    location /ntfy/ {
        proxy_pass http://ntfy:80/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # File Browser - /drive
    location /drive/ {
        proxy_pass http://filebrowser:8080/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Code Server (VS Code in the Browser) - /code
    location /code/ {
        # The rewrite helps Code Server function correctly when not on the root path
        rewrite ^/code/(.*)$ /\$1 break;
        proxy_pass https://codeserver:8443;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Required for WebSockets (terminal, etc.)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        
        proxy_ssl_verify off; # Trust the self-signed certificate inside the container
    }

    # Jellyfin (Media Server) - SITE-WIDE LOCATION (location /)
    # If none of the above paths match, the request goes to Jellyfin.
    location / {
        proxy_pass http://jellyfin:8096;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Jellyfin WebSockets support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        
        # This is a general rule and should be after specific paths
        try_files \$uri \$uri/ =404;
    }

    # Uptime Kuma (Monitoring dashboard) is still direct-access on port 3001.

}
EOF
)

echo "$NGINX_CONF_CONTENT" > "$NGINX_CONF_PATH/default.conf"
echo "Nginx configuration file written to $NGINX_CONF_PATH/default.conf"


# --- Step 5: Create docker-compose.yml ---
echo "5. Generating $COMPOSE_FILE with new services..."

cat <<EOF > $COMPOSE_FILE
version: "3.8"

services:
  # Nginx Reverse Proxy (Handles all external traffic on port 80)
  nginx:
    container_name: nginx
    image: nginx:latest
    restart: unless-stopped
    volumes:
      # Mount the generated configuration
      - $NGINX_CONF_PATH/default.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "80:80" # Primary HTTP access point
      
  # Portainer (Docker Management GUI)
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
    # No external port exposed, accessed via Nginx: http://<PiIP>/docker

  # Jellyfin (Media Server)
  jellyfin:
    container_name: jellyfin
    image: jellyfin/jellyfin:latest
    restart: unless-stopped
    environment:
      - PUID=$PUID
      - PGID=$PGID
      - TZ=$TIMEZONE
      # Set the published URL to match the Nginx root proxy
      - JELLYFIN_PublishedServerUrl=http://<YourPiIP> 
    volumes:
      - $DATA_ROOT/jellyfin/config:/config
      - $DATA_ROOT/jellyfin/cache:/cache
      # IMPORTANT: Map your actual media folders here
      - $DATA_ROOT/media:/data/media:rw
      # Uncomment for hardware transcoding (Pi 4 only)
      # - /dev/dri:/dev/dri
    # Ports are mapped internally only for networking with Nginx, not externally

  # File Browser (Simple Web File Browser)
  filebrowser:
    container_name: filebrowser
    image: filebrowser/filebrowser:latest
    restart: unless-stopped
    environment:
      - PUID=$PUID
      - PGID=$PGID
      - TZ=$TIMEZONE
      - FB_BASEURL=/drive # Required for path-based proxying
    volumes:
      - $DATA_ROOT/filebrowser/config:/config
      - $DATA_ROOT/media:/srv # Maps to your files
    # No external port exposed, accessed via Nginx: http://<PiIP>/drive

  # Ntfy (Self-hosted push notification service)
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
    # No external port exposed, accessed via Nginx: http://<PiIP>/ntfy
      
  # Uptime Kuma (Monitoring dashboard)
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
    ports:
      - "3001:3001" # Direct port access kept for simplicity
      
  # Code Server (VS Code in the Browser)
  codeserver:
    container_name: codeserver
    image: linuxserver/codeserver:latest
    restart: unless-stopped
    environment:
      - PUID=$PUID
      - PGID=$PGID
      - TZ=$TIMEZONE
      - PASSWORD=yourstrongpassword # <<< CHANGE THIS!
      - URL_BASE=/code # Required for path-based proxying
    volumes:
      - $DATA_ROOT/codeserver/config:/config
      # Mount the Pi's file system for coding:
      - /home/$USER:/home/coder/project
    # No external port exposed, accessed via Nginx: http://<PiIP>/code
      
EOF

echo "$COMPOSE_FILE generated successfully."

# --- Step 6: Start Services ---
echo "6. Bringing up all services with Docker Compose..."

# Restart the daemon and compose to pick up Nginx and the new config
sudo systemctl daemon-reload
docker compose up -d

if [ $? -eq 0 ]; then
    echo -e "\n--- Deployment Complete! ---"
    echo "All services are running in the background, proxied by Nginx."
    echo "REMINDER: If this is the first run, you MUST log out and log back in for 'docker' group permissions to take effect."
else
    echo -e "\n!!! Deployment Failed !!!"
    echo "Docker Compose failed to start the containers."
    echo "If this is the first run, please log out and back in, then run: docker compose up -d"
fi

# --- Step 7: Access Information ---
echo -e "\n--- Access Information ---"
PI_IP=$(hostname -I | awk '{print $1}')
echo "Your Pi's IP Address is likely: $PI_IP"
echo ""
echo "Jellyfin is now your site-wide service on port 80:"
echo "Jellyfin (Media Server):       http://$PI_IP/"
echo ""
echo "Other services are accessed via subpaths:"
echo "Portainer (Docker Management): http://$PI_IP/docker"
echo "File Browser (Files):          http://$PI_IP/drive"
echo "Ntfy (Push Notifications):     http://$PI_IP/ntfy"
echo "Code Server (VS Code):         http://$PI_IP/code (Login: user, Password: yourstrongpassword - CHANGE IT!)"
echo ""
echo "Uptime Kuma (Monitoring) is still direct-access for simplicity:"
echo "Uptime Kuma:                   http://$PI_IP:3001"
echo ""
echo "Data Directory: $DATA_ROOT"
echo "-------------------------------------"
