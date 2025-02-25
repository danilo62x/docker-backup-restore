# Docker Backup and Restore Script

## Overview

This script automates the backup and restoration of Docker images, containers, and volumes. It performs the following tasks:

- **Backup:**
  - Saves Docker images using `docker save`.
  - Exports containers with `docker export`.
  - Archives volume data via a temporary Alpine container.
  - Generates a `run_containers.sh` file that contains Docker run commands reflecting each container’s original configuration (including port mappings, environment variables, and mounts).

- **Restore:**
  - Loads the saved images with `docker load`.
  - Restores volume data by recreating volumes and extracting archived files.
  - Reads the generated `run_containers.sh` file to recreate containers. If a container with the same name exists, it is automatically removed to prevent conflicts.

This integrated solution simplifies migrating Docker environments between servers.

## Requirements

- Docker must be installed on your system.
- Bash shell environment.
- Standard Unix utilities such as `sed`, `mkdir`, and others.

## Usage

### Backup

To create a backup of your Docker environment, run:

\```bash
./docker_backup.sh backup
\```

This command will generate a `docker_backup` directory containing:

- **images/**: Saved Docker images (via `docker save`).
- **containers/**: Exported containers (via `docker export`).
- **volumes/**: Archived volume data.
- **run_containers.sh**: A script with Docker run commands to recreate the containers with their original configurations.

### Restore

After transferring the `docker_backup` directory to your destination server, restore your Docker environment by running:

\```bash
./docker_backup.sh restore
\```

This command will:

- Load the Docker images (via `docker load`).
- Recreate volumes and restore their data.
- Execute the `run_containers.sh` script to recreate the containers. Any existing containers with conflicting names will be removed automatically before recreation.

## How It Works

1. **Backup Process:**
   - **Images:** Uses `docker save` to export images to `.tar` files.
   - **Containers:** Uses `docker export` to save container filesystems.
   - **Volumes:** Copies volume data into `.tar.gz` archives.
   - **Run Config:** Generates a `run_containers.sh` script with exact `docker run` commands to recreate containers.

2. **Restore Process:**
   - **Images:** Uses `docker load` to import saved images.
   - **Volumes:** Recreates Docker volumes and restores data.
   - **Containers:** Runs the `run_containers.sh` to recreate containers, removing existing ones with the same names to avoid conflicts.

## Disclaimer

This script is a basic tool for automating the migration of Docker environments. Some container configurations (such as advanced network settings, custom environment variables, or external dependencies) might require manual adjustments. Always test the backup and restore process in a safe environment before applying it to production systems.

## License

- No License
