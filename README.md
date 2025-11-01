[![Build Status](http://drone.kernelsanders.biz:8080/api/badges/kernel528/clickhouse-docker/status.svg?ref=refs/heads/main)](http://drone.kernelsanders.biz:8080/kernel528/clickhouse-docker)[![Latest Version](https://img.shields.io/github/v/tag/kernel528/clickhouse-docker)](https://github.com/kernel528/clickhouse-docker/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/kernel528/clickhouse)](https://hub.docker.com/r/kernel528/clickhouse)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/clickhouse)](https://hub.docker.com/r/kernel528/clickhouse/)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kernel528/clickhouse?sort=semver)](https://hub.docker.com/r/kernel528/clickhouse)

# Source repo for: kernel528:/clickhouse-docker Docker image
* Based on upstream github:  https://github.com/ClickHouse/ClickHouse/tree/master/docker/server
* Based on upstream hub.docker.io:  https://hub.docker.com/r/clickhouse/clickhouse-server

### Overview
This image is intended to standup a vanilla alpine-linux based clickhouse instance running in docker.

### Base Image Prep Steps
- Use the upstream `Dockerfile.alpine` as base Dockerfile.
- Update the local `Dockerfile` with latest clickhouse version.
  - NOTE: Double-check the UID and GUID used.  I use 110 to avoid some conflicts.
- Update the `.drone.yml` version info.
- Confirm `entrypoint.sh` is up-to-date.  
- Update `clickhouse-stack-kernel528.yml` to latest version.

### How to Build
``docker build -t kernel528/clickhouse-docker:<version> -f Dockerfile .``

### Running
This is currently focused on deploying into a local `docker swarm` cluster.  This uses the `clickhouse-stack-kernel528.yml` file as the basis.
- This uses a local NAS hosted volume for persistence.
- It currently uses a lot of CPU so is not run unless actively testing.

### Using image:
To use this image, add this to a downstream image Dockerfile:  
``FROM kernel528/clickhouse-docker``

### Running
``$ docker run -it --rm --name clickhouse --hostname docker-clickhouse -e TZ=CST kernel528/clickhouse bash``

### Using image:
To use this image, add this to a downstream image Dockerfile:  
``FROM kernel528/clickhouse:latest``


### Authors
* **kernel528** - (kernel528@gmail.com)
