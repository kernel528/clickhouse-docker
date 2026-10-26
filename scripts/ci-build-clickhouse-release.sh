#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_NUMBER:?Drone build number is required}"
: "${DRONE_BUILD_EVENT:?Drone build event is required}"
: "${DRONE_TAG:?Release tag is required}"
: "${DRONE_COMMIT_REF:?Git ref is required}"
: "${DRONE_COMMIT_SHA:?Commit SHA is required}"

if [ "$DRONE_BUILD_EVENT" != tag ] || [ "$DRONE_COMMIT_REF" != "refs/tags/$DRONE_TAG" ]; then
  printf '%s\n' 'ClickHouse release builds require their matching Git tag event.' >&2
  exit 1
fi

base_ref=$(awk '$1 == "FROM" && $2 ~ /^kernel528\/alpine:/ { print $2; exit }' Dockerfile)
base_tag=${base_ref##*:}
expected_alpine=${base_tag%_*}
clickhouse_version=$(awk '$1 == "ARG" && $2 ~ /^VERSION=/ { sub(/^VERSION=/, "", $2); gsub(/"/, "", $2); print $2; exit }' Dockerfile)
release_date=${DRONE_TAG#"${clickhouse_version}-"}
expected_tag="${clickhouse_version}-${release_date}"
image="localhost/clickhouse-release:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"

case "$DRONE_TAG" in
  "${clickhouse_version}-"*) ;;
  *) printf 'ClickHouse release tag must start with %s-.\n' "$clickhouse_version" >&2; exit 1 ;;
esac
case "$release_date" in
  ??????) ;;
  *) printf 'ClickHouse release tag must end in a six-digit YYMMDD date: %s\n' "$DRONE_TAG" >&2; exit 1 ;;
esac
case "$release_date" in
  *[!0-9]*) printf 'ClickHouse release date must be numeric: %s\n' "$release_date" >&2; exit 1 ;;
esac
if [ "$DRONE_TAG" != "$expected_tag" ]; then
  printf 'ClickHouse release tag mismatch: expected %s, got %s.\n' "$expected_tag" "$DRONE_TAG" >&2
  exit 1
fi

attempt=0
until docker info >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    printf '%s\n' 'Docker-in-Docker service did not become ready.' >&2
    exit 1
  fi
  sleep 1
done

docker build --pull --no-cache --tag "$image" .
image_id=$(docker image inspect --format '{{.Id}}' "$image")
printf 'ClickHouse release source commit: %s\n' "$DRONE_COMMIT_SHA"
printf 'ClickHouse release tag: %s\n' "$DRONE_TAG"
printf 'ClickHouse release image ID: %s\n' "$image_id"
scripts/ci-smoke-clickhouse-image.sh "$image_id" "$expected_alpine" "$clickhouse_version"

umask 077
printf '%s\n' "$image_id" > .drone-clickhouse-image-id
printf '%s\n' "$DRONE_TAG" > .drone-clickhouse-release-tag
printf '%s\n' "$DRONE_COMMIT_SHA" > .drone-clickhouse-commit
