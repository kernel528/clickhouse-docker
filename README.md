[![Build Status](http://drone.kernelsanders.biz:8080/api/badges/kernel528/clickhouse-docker/status.svg?ref=refs/heads/main)](http://drone.kernelsanders.biz:8080/kernel528/clickhouse-docker)
[![Latest Version](https://img.shields.io/github/v/tag/kernel528/clickhouse-docker)](https://github.com/kernel528/clickhouse-docker/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/kernel528/clickhouse)](https://hub.docker.com/r/kernel528/clickhouse)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/clickhouse)](https://hub.docker.com/r/kernel528/clickhouse/)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kernel528/clickhouse?sort=semver)](https://hub.docker.com/r/kernel528/clickhouse)

# clickhouse-docker

Maintainer: kernel528

## Overview
This repository builds an Alpine-based ClickHouse server image from the upstream `Dockerfile.alpine`. It uses Ubuntu as a donor stage for glibc artifacts and `kernel528/alpine:3.24.1_1` as the final runtime base. Current package version is `26.5.5.8` (stable channel).

Upstream references:
- https://github.com/ClickHouse/ClickHouse/blob/master/docker/server/Dockerfile.alpine
- https://hub.docker.com/r/clickhouse/clickhouse-server

## Project Structure
- `Dockerfile`: Image build using ClickHouse TGZ packages.
- `entrypoint.sh`: Startup entrypoint used by the container.
- `docker_related_config.xml`: Extra config loaded into `config.d/`.
- `.drone.yml`: CI build/tag configuration.

## Build
```bash
docker build -t kernel528/clickhouse:26.5.5.8-3.24.1_1 -f Dockerfile .
```

## Run
```bash
docker run -d --name clickhouse -p 8123:8123 -p 9000:9000 kernel528/clickhouse:26.5.5.8-3.24.1_1
```

## Refresh Workflow
1) Review both supply-chain inputs: the Ubuntu donor tag and the published `kernel528/alpine` runtime-base tag.
2) Update `Dockerfile` to the latest intended ClickHouse version and base tags.
3) Verify UID/GID settings (this repo uses `110` to avoid conflicts).
4) Update `.drone.yml` tags for the new version.
5) Build and smoke-test the image before publishing an immutable release tag.
6) Update and validate the `docker-swarm` stack only after the release tag resolves.

## Repository Relationships

This independent repository is coordinated by [`docker-workspace`](https://github.com/kernel528/docker-workspace). Its published image is consumed by [`docker-swarm`](https://github.com/kernel528/docker-swarm) in `stacks/clickhouse-stack.yml`. Keep image publication and the persistence-sensitive Swarm rollout as separate reviewed changes.

## Notes
- Swarm stack definition lives in the `docker-swarm` repo.
- `CLICKHOUSE_CONFIG` defaults to `/etc/clickhouse-server/config.xml`.
