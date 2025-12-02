# 🏠 Home Server Installer

Welcome! This script automates the deployment of a **turn-key home server suite** on your Raspberry Pi or compatible Linux machine using Docker and Docker Compose. With a single script, you get a fully configured reverse-proxy, several useful self-hosted apps, persistent storage setup, and simple web access.

---

## ✨ Features

* **Automated install** of Docker, Docker Compose, and all applications.
* **Centralized data storage**: All apps keep data under `/pi-data` for easy backup and management.
* **Nginx reverse proxy**: Friendly URLs via subpaths (e.g., `/drive` for File Browser).
* **Root Dashboard**: **Uptime Kuma** is configured to load on the home page (`http://<PiIP>/`).
* **Auto-generated config files** for both Nginx and Docker Compose.
* **Automatic detection** of user/group ID and timezone for Docker permissions.

---

## 📦 Installed Applications

| Application | Description | Default URL |
| :--- | :--- | :--- |
| **Uptime Kuma** | **Main Dashboard:** Service & website uptime monitoring | `http://<PiIP>/` |
| **Jellyfin** | Media server—access your music, TV, movies | `http://<PiIP>/jellyfin` |
| **Portainer** | Manage Docker containers and images | `http://<PiIP>/docker` |
| **File Browser** | Simple web-based file manager | `http://<PiIP>/drive` |
| **Ntfy** | Push notification service | `http://<PiIP>/ntfy` |
| **Code Server** | VS Code in browser (remote coding) | `http://<PiIP>/code` |

---

## 📁 Configuration & Data Paths

All persistent data, generated configs, and media files are stored in the root directory `/pi-data`.

| Path | Description |
| :--- | :--- |
| `/pi-data/media` | Place your movies, music, etc. here! (Mapped to File Browser and Jellyfin) |
| `/pi-data/nginx/conf.d/default.conf` | Nginx main site config |
| `/pi-data/uptime-kuma/data` | Uptime Kuma configs |
| `/pi-data/jellyfin/config`, `/pi-data/jellyfin/cache` | Jellyfin configs/cache |
| `/pi-data/portainer/data` | Portainer database |
| `/pi-data/codeserver/config` | Code Server configs |
| `/pi-data/filebrowser/config` | File Browser configs |
| `/pi-data/ntfy/data` | Ntfy message data |

---

## ⚙️ Setup Instructions

### 1. **Prerequisites**
* Raspberry Pi (4 recommended), or any Debian-based Linux machine
* User with `sudo` privileges
* Internet access

### 2. **Run the Installer Script**

Assuming you saved the script as `install.sh`:

```bash
chmod +x install.sh         # Make the installer executable
./install.sh                # Start the automated setup
````

The script will prompt you to choose **1** for installation.

#### What the script does:

1.  Updates your system packages.
2.  Installs Docker and Docker Compose.
3.  Adds your user to the Docker group.
4.  Creates all app data folders under `/pi-data`.
5.  Generates Nginx and `docker-compose.yml` configuration files.
6.  Starts up all services via `sudo docker compose up -d`.
7.  Prints all access URLs.

### 3\. **Post-Install Instructions**

  * **Log out and log back in** after install so Docker group permissions apply to your user (allowing you to run `docker` commands without `sudo`).
  * **Change the default password** for Code Server in `docker-compose.yml` (`yourstrongpassword`).
  * Connect to your apps using your Pi's IP and the listed subpaths.

-----

## 🌐 Accessing Your Services

**Replace `<PiIP>` with your Raspberry Pi's IP on the network (shown at install finish).**

| Application | Access URL Example | Notes |
| :--- | :--- | :--- |
| **Uptime Kuma** | `http://<PiIP>/` | Main monitoring dashboard. |
| **Jellyfin** | `http://<PiIP>/jellyfin` | Media server interface. |
| **Portainer** | `http://<PiIP>/docker` | Docker management web UI. |
| **File Browser** | `http://<PiIP>/drive` | Web file manager for `/pi-data/media`. |
| **Ntfy** | `http://<PiIP>/ntfy` | Push notification service. |
| **Code Server** | `http://<PiIP>/code` | VSCode in browser (change password\!). |

-----

## 🛠️ Service Management Commands

These commands should be run in the directory where the `docker-compose.yml` file is located.

```bash
# Start all apps
docker compose up -d      

# Stop all apps
docker compose down       

# Restart a specific service (e.g., jellyfin)
docker compose restart jellyfin

# View logs of a service
docker compose logs jellyfin

# List all running containers
docker ps
```

-----

## 💡 Customization

  * **Add your media files:** Place them into `/pi-data/media` (accessible by both Jellyfin and File Browser).
  * **Enable hardware transcoding:** For Pi 4, you may need to uncomment relevant device mappings (like `/dev/dri:/dev/dri`) in `docker-compose.yml` under the `jellyfin` service.
  * **Edit Nginx proxy rules:** Change the file at `/pi-data/nginx/conf.d/default.conf`.

-----

## 🛑 Troubleshooting

  * If containers don’t start, **log out and log back in**, then run:
    ```bash
    docker compose up -d
    ```
  * If accessing services fails, check container logs for errors:
    ```bash
    docker compose logs <service>
    ```

-----

## 🗑️ Uninstallation

To uninstall the OpenSon stack and remove all related Docker services and data:

1.  Run the installer script:
    ```bash
    bash install.sh
    ```
2.  When prompted, type **2** to select the uninstall option.
3.  Confirm to proceed.

**Warning:** This process will remove the entire `/pi-data` directory containing all persistent data and uninstall Docker from your system.

-----

## ⚖️ License

Open source - no license yet.

```
```
