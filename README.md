# Home Server Installer

Welcome! This script automates the deployment of a *turn-key home server suite* on your Raspberry Pi or compatible Linux machine using Docker and Docker Compose. With a single script, you get a fully configured reverse-proxy, several useful self-hosted apps, persistent storage setup, and simple web access. 

---

## Features

- **Automated install** of Docker, Docker Compose, and all applications.
- **Centralized data storage**: All apps keep data under `/pi-data` for easy backup and management.
- **Nginx reverse proxy**: Friendly URLs via subpaths (e.g., `/drive` for File Browser).
- **Auto-generated config files** for both Nginx and Docker Compose.
- **Preconfigured volumes** for all persistent app data.
- **Automatic detection** of user/group ID and timezone for Docker permissions.

---

## Installed Applications

| Application    | Description                                | Default URL                      |
|----------------|--------------------------------------------|----------------------------------|
| **Jellyfin**   | Media server—access your music, TV, movies | `http://<PiIP>/`                 |
| **Portainer**  | Manage Docker containers and images         | `http://<PiIP>/docker`           |
| **File Browser** | Simple web-based file manager             | `http://<PiIP>/drive`            |
| **Ntfy**       | Push notification service                   | `http://<PiIP>/ntfy`             |
| **Code Server**| VS Code in browser (remote coding)          | `http://<PiIP>/code`             |
| **Uptime Kuma**| Service & website uptime monitoring         | `http://<PiIP>:3001`             |

---

## Configuration & Data Paths

All persistent data, generated configs, and media files are stored in `/pi-data`. Here’s a breakdown:

- `/pi-data/jellyfin/config`, `/pi-data/jellyfin/cache`: Jellyfin configs/cache
- `/pi-data/media`: Place your movies, music, etc. here!
- `/pi-data/ntfy/data`: Ntfy message data
- `/pi-data/uptime-kuma/data`: Uptime Kuma configs
- `/pi-data/portainer/data`: Portainer database
- `/pi-data/codeserver/config`: Code Server configs
- `/pi-data/nginx/conf.d/default.conf`: Nginx main site config
- `/pi-data/filebrowser/config`: File Browser configs

---

## Setup Instructions

### 1. **Prerequisites**
- Raspberry Pi (4 recommended), or any Debian-based Linux machine
- User with `sudo` privileges
- Internet access

### 2. **Run the Installer Script**

```bash
chmod +x install.sh       # Make the installer executable
./install.sh              # Start the automated setup
```

#### What these commands do:
- `chmod +x install.sh` — allows the script to run.
- `./install.sh` — steps through the entire install: 
    1. Updates your system packages (`apt update/upgrade`)
    2. Installs Docker and Docker Compose (via official scripts)
    3. Adds your user to the Docker group (no sudo needed for docker)
    4. Creates all app data folders under `/pi-data`
    5. Auto-generates Nginx config for reverse proxy routing
    6. Generates a complete `docker-compose.yml` with all defined services and persistent data mapping 
    7. Starts up all services via Docker Compose
    8. Prints all access URLs and caveats

### 3. **Post-Install Instructions**

- **Log out and back in** after install so Docker group permissions apply to your user.
- **Change the default password** for Code Server in `docker-compose.yml` (`yourstrongpassword`).
- Connect to your apps using IP and listed subpaths.

---

## Accessing Your Services

| Application      | Access URL Example                    | Notes                         |
|------------------|--------------------------------------|-------------------------------|
| Jellyfin         | `http://<PiIP>/`                     | Main site, all root requests  |
| Portainer        | `http://<PiIP>/docker`               | Manage Docker via web UI      |
| File Browser     | `http://<PiIP>/drive`                | Web file manager              |
| Ntfy             | `http://<PiIP>/ntfy`                 | Push notifications            |
| Code Server      | `http://<PiIP>/code`                 | VSCode in browser (change password!) |
| Uptime Kuma      | `http://<PiIP>:3001`                 | Uptime monitor (direct port)  |

**Replace `<PiIP>` with your Raspberry Pi's IP on the network (shown at install finish).**

---

## Service Management Commands

- **Start/stop all containers:**
    ```bash
    docker compose up -d    # Start all apps
    docker compose down     # Stop all apps
    ```
- **Restart a specific service (e.g., Jellyfin):**
    ```bash
    docker compose restart jellyfin
    ```
- **View logs of a service:**
    ```bash
    docker compose logs jellyfin
    ```
- **List all running containers:**
    ```bash
    docker ps
    ```

---

## Customization

- **Add your media files:** Place them into `/pi-data/media` before launching Jellyfin.
- **Enable hardware transcoding:** For Pi 4, uncomment `/dev/dri:/dev/dri` in `docker-compose.yml` under Jellyfin.
- **Edit Nginx proxy rules:** Change `/pi-data/nginx/conf.d/default.conf`.
- **Change Code Server password:** Edit the environment variable in `docker-compose.yml`.
- **Add new services:** Extend `docker-compose.yml` and update Nginx config to create new subpaths.

---

## Troubleshooting

- If containers don’t start, **log out and log back in** (for Docker group permissions), then run:
    ```bash
    docker compose up -d
    ```
- If accessing services fails, check container logs for errors:
    ```bash
    docker compose logs <service>
    ```
- Make sure you put media files in `/pi-data/media` (for Jellyfin/File Browser).

---

## Uninstallation

To remove:
- Run `docker compose down`
- Optionally delete `/pi-data` and config files manually

---

## License

Open source no license yet
