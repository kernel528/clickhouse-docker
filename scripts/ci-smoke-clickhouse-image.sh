#!/usr/bin/env sh
set -eu

image_id=${1:?Usage: ci-smoke-clickhouse-image.sh <image-id> <alpine-release> <clickhouse-version>}
expected_alpine=${2:?Usage: ci-smoke-clickhouse-image.sh <image-id> <alpine-release> <clickhouse-version>}
expected_clickhouse=${3:?Usage: ci-smoke-clickhouse-image.sh <image-id> <alpine-release> <clickhouse-version>}

actual_alpine=$(docker container run --rm "$image_id" cat /etc/alpine-release)
if [ "$actual_alpine" != "$expected_alpine" ]; then
  printf 'Alpine release mismatch: expected %s, got %s\n' "$expected_alpine" "$actual_alpine" >&2
  exit 1
fi

server_output=$(docker container run --rm "$image_id" clickhouse-server --version 2>&1)
case "$server_output" in
  *"${expected_clickhouse}"*) ;;
  *) printf 'ClickHouse version mismatch; expected %s, got:\n%s\n' "$expected_clickhouse" "$server_output" >&2; exit 1 ;;
esac

client_output=$(docker container run --rm "$image_id" clickhouse-client --version 2>&1)
case "$client_output" in
  *"${expected_clickhouse}"*) ;;
  *) printf 'ClickHouse client version mismatch; expected %s, got:\n%s\n' "$expected_clickhouse" "$client_output" >&2; exit 1 ;;
esac

printf 'ClickHouse smoke checks passed: Alpine %s, server/client %s.\n' \
  "$actual_alpine" "$expected_clickhouse"
