#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_NUMBER:?Drone build number is required}"
: "${DRONE_COMMIT_SHA:?Drone commit SHA is required}"

image="localhost/clickhouse-ci:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"
base_ref=$(awk '$1 == "FROM" && $2 ~ /^kernel528\/alpine:/ { print $2; exit }' Dockerfile)
base_tag=${base_ref##*:}
expected_alpine=${base_tag%_*}
clickhouse_version=$(awk '$1 == "ARG" && $2 ~ /^VERSION=/ { sub(/^VERSION=/, "", $2); gsub(/"/, "", $2); print $2; exit }' Dockerfile)

if [ -z "$base_tag" ] || [ -z "$expected_alpine" ] || [ -z "$clickhouse_version" ]; then
  printf '%s\n' 'Could not determine the pinned Alpine base or ClickHouse version.' >&2
  exit 1
fi

cleanup() {
  rc=$?
  trap - EXIT
  if docker image inspect "$image" >/dev/null 2>&1; then
    docker image rm --no-prune "$image" || rc=1
  fi
  exit "$rc"
}
trap cleanup EXIT

docker build --pull --no-cache --tag "$image" .
image_id=$(docker image inspect --format '{{.Id}}' "$image")
printf 'Rootless ClickHouse image ID: %s\n' "$image_id"
scripts/ci-smoke-clickhouse-image.sh "$image_id" "$expected_alpine" "$clickhouse_version"
