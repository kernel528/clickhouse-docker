[![Build Status](https://drone.kernelsanders.biz:8443/api/badges/kernel528/clickhouse-docker/status.svg?ref=refs/heads/main)](https://drone.kernelsanders.biz:8443/kernel528/clickhouse-docker)
[![Latest Version](https://img.shields.io/github/v/tag/kernel528/clickhouse-docker)](https://github.com/kernel528/clickhouse-docker/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/kernel528/clickhouse)](https://hub.docker.com/r/kernel528/clickhouse)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/kernel528/clickhouse)](https://hub.docker.com/r/kernel528/clickhouse/)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kernel528/clickhouse?sort=semver)](https://hub.docker.com/r/kernel528/clickhouse)

# clickhouse-docker

Maintainer: kernel528

## Overview
This repository builds an Alpine-based ClickHouse server image from the upstream `Dockerfile.alpine`. It uses Ubuntu as a donor stage for glibc artifacts and `kernel528/alpine:3.24.3_3` as the final runtime base. Current package version is `26.5.7.64` (stable channel).

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
docker build -t kernel528/clickhouse:26.5.7.64-3.24.3_3 -f Dockerfile .
```

## Run
```bash
docker run -d --name clickhouse -p 8123:8123 -p 9000:9000 kernel528/clickhouse:26.5.7.64-3.24.3_3
```

## Refresh Workflow
1) Review both supply-chain inputs: the Ubuntu donor tag and the published `kernel528/alpine` runtime-base tag.
2) Update `Dockerfile` to the latest intended ClickHouse version and base tags.
3) Verify UID/GID settings (this repo uses `110` to avoid conflicts).
4) Open a PR targeting `26`. Rootless validation builds and smoke-tests the exact image without registry credentials or publication.
5) Merge to `26` to publish a unique non-deployable candidate, then promote to `main` after validation.
6) Create a Git tag from reviewed `main` using the existing `26.5.7.64-YYMMDD` convention. The tag pipeline freshly builds and smoke-tests the image, refuses to overwrite the immutable tag, then updates `26.5`, `26.5.7`, `26.5.7.64`, and `latest` to the tested image.
7) Update and validate the `docker-swarm` stack only after the immutable release tag resolves; review ClickHouse persistence and rollback before any deployment change.

## Repository Relationships

This independent repository is coordinated by [`docker-workspace`](https://github.com/kernel528/docker-workspace). Its published image is consumed by [`docker-swarm`](https://github.com/kernel528/docker-swarm) in `stacks/clickhouse-stack.yml`. Keep image publication and the persistence-sensitive Swarm rollout as separate reviewed changes.

## CI validation and release policy

- Pull requests targeting `26` run rootless exact-image ClickHouse version checks; the job receives no registry credentials and publishes nothing.
- Pushes to `26` build and smoke-test a fresh DIND candidate before a separate credentialed step publishes a unique build-number candidate tag.
- Git tags from reviewed `main` use `26.5.7.64-YYMMDD`; the pipeline freshly builds and smoke-tests the immutable release before moving version aliases and `latest`.
- Candidate tags are not deployment inputs. No stack, volume, or persistence configuration is changed by the image refresh.
- This repository is public and must be trusted in Drone and added to the isolated runner's exact repository allowlist after pipeline review. Rootless PR jobs receive no registry credentials.

## Notes
- Swarm stack definition lives in the `docker-swarm` repo.
- `CLICKHOUSE_CONFIG` defaults to `/etc/clickhouse-server/config.xml`.
