# Home Server Installer

This installer script sets up a complete home server environment on your Raspberry Pi (or compatible Linux device) using Docker and Docker Compose. It deploys several apps, configures persistent storage, and enables easy access via Nginx reverse proxy.

---

## Features

- Automated installation and deployment of multiple self-hosted services with Docker Compose.
- Nginx reverse proxy for access via friendly subpaths.
- Centralized data storage paths.
- Auto-generated configuration files for Nginx and each app.
- Persistent volumes for each application.
- Automatic network and group/user ID detection.

---

## Included Applications

| App           | Description                              | URL                      |
|---------------|------------------------------------------|--------------------------|
| Jellyfin      | Media server (site-wide service)         | `http://<PiIP>/`         |
| Portainer     | Docker management UI                     | `http://<PiIP>/docker`   |
| File Browser  | Web-based file manager                   | `http://<PiIP>/drive`    |
| Ntfy          | Push notification service                | `http://<PiIP>/ntfy`     |
| Code Server   | VS Code in the browser                   | `http://<PiIP>/code`     |
| Uptime Kuma   | Monitoring dashboard                     | `http://<PiIP>:3001`     |

---

## Configuration Changes

- **Docker & Docker Compose**: Installed automatically using official scripts.
- **Nginx**: Configured as a reverse proxy, serving all applications on subpaths. Uses an auto-generated config file at `/pi-data/nginx/conf.d/default.conf`.
- **docker-compose.yml**: Auto-generated with all service definitions.
- **Persistent Data Directories** (created automatically under `/pi-data`):
  - `/pi-data/jellyfin/config` and `/pi-data/jellyfin/cache`
  - `/pi-data/media` (where you should put your media files)
  - `/pi-data/ntfy/data`
  - `/pi-data/uptime-kuma/data`
  - `/pi-data/portainer/data`
  - `/pi-data/codeserver/config`
  - `/pi-data/nginx/conf.d`
  - `/pi-data/filebrowser/config`

---

## Setup Instructions

1. **Prerequisites**
    - Raspberry Pi, or compatible Linux machine
    - OS: Debian-based recommended
    - User must have sudo privileges

2. **Run the Installer**
    ```bash
    chmod +x install.sh
    ./install.sh
    ```
    > The script installs Docker, sets up all apps, configures persistent storage, and launches all services.

3. **Post-Installation**
    - Log out and back in for Docker group permissions to apply!
    - Make sure to change the default password for Code Server (`yourstrongpassword` in `docker-compose.yml`).

---

## Accessing Your Services

- **Jellyfin** (Main site): `http://<YourPiIP>/`
- **Portainer**: `http://<YourPiIP>/docker`
- **File Browser**: `http://<YourPiIP>/drive`
- **Ntfy**: `http://<YourPiIP>/ntfy`
- **Code Server**: `http://<YourPiIP>/code` (Default login: user / yourstrongpassword)
- **Uptime Kuma**: `http://<YourPiIP>:3001`

---

## Customization

- **Media Storage**: Place your media files into `/pi-data/media` for Jellyfin and File Browser.
- **Hardware Transcoding**: For Raspberry Pi 4, uncomment `/dev/dri:/dev/dri` in `docker-compose.yml` under the Jellyfin service.
- **Nginx Config**: Located at `/pi-data/nginx/conf.d/default.conf`, edit for advanced routes or SSL setup.
- **Service Passwords**: Change passwords, especially for Code Server.

---

## Troubleshooting

- If containers fail to start, log out and back in, then run:
    ```bash
    docker compose up -d
    ```

---

## Uninstallation

Stop all containers and remove generated files and directories manually.

---

## License

Open source under [your chosen license].

---

*Generated and maintained by the Home Server Installer script.*
