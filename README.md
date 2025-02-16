[![Build Status](http://drone.kernelsanders.biz:8080/api/badges/kernel528/clickhouse-docker/status.svg?ref=refs/heads/3.21)](http://drone.kernelsanders.biz:8080/kernel528/clickhouse-docker)
[![Latest Version](https://img.shields.io/github/v/tag/kernel528/clickhouse-docker)](https://github.com/kernel528/clickhouse-docker/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/kernel528/clickhouse)](https://hub.docker.com/r/kernel528/clickhouse)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/clickhouse)](https://hub.docker.com/r/kernel528/clickhouse/)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kernel528/clickhouse?sort=semver)](https://hub.docker.com/r/kernel528/clickhouse)

# This repo contains the base docker image for kernel528:/clickhouse-docker

### Overview
This image is intended to standup a vanilla alpine-linux based clickhouse instance running in docker.

### How to Build
``docker build -t kernel528/clickhouse-docker:<version> -f Dockerfile .``

### Running
``TBD``

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
