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
- Standard Unix utilities such as `sed` and `mkdir`.

## Usage

### Backup

To create a backup of your Docker environment, run:

```bash
./docker_backup.sh backup
