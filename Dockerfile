FROM ubuntu:22.04 AS glibc-donor
ARG TARGETARCH

RUN arch=${TARGETARCH:-amd64} \
    && case $arch in \
        amd64) rarch=x86_64 ;; \
        arm64) rarch=aarch64 ;; \
    esac \
    && ln -s "${rarch}-linux-gnu" /lib/linux-gnu \
    && case $arch in \
        amd64) ln /lib/linux-gnu/ld-linux-x86-64.so.2 /lib/linux-gnu/ld-2.35.so ;; \
        arm64) ln /lib/linux-gnu/ld-linux-aarch64.so.1 /lib/linux-gnu/ld-2.35.so ;; \
    esac

FROM kernel528/alpine:3.22.1

# Set to root user to install packages
USER root

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC \
    CLICKHOUSE_CONFIG=/etc/clickhouse-server/config.xml

COPY --from=glibc-donor /lib/linux-gnu/libc.so.6 /lib/linux-gnu/libdl.so.2 /lib/linux-gnu/libm.so.6 /lib/linux-gnu/libpthread.so.0 /lib/linux-gnu/librt.so.1 /lib/linux-gnu/libnss_dns.so.2 /lib/linux-gnu/libnss_files.so.2 /lib/linux-gnu/libresolv.so.2 /lib/linux-gnu/ld-2.35.so /lib/
COPY --from=glibc-donor /etc/nsswitch.conf /etc/
COPY docker_related_config.xml /etc/clickhouse-server/config.d/
COPY entrypoint.sh /entrypoint.sh

ARG TARGETARCH
RUN arch=${TARGETARCH:-amd64} \
    && case $arch in \
        amd64) mkdir -p /lib64 && ln -sf /lib/ld-2.35.so /lib64/ld-linux-x86-64.so.2 ;; \
        arm64) ln -sf /lib/ld-2.35.so /lib/ld-linux-aarch64.so.1 ;; \
    esac

# lts / testing / prestable / etc
ARG REPO_CHANNEL="stable"
ARG REPOSITORY="https://packages.clickhouse.com/tgz/${REPO_CHANNEL}"
ARG VERSION="25.6.5.41"
ARG PACKAGES="clickhouse-client clickhouse-server clickhouse-common-static"
ARG DIRECT_DOWNLOAD_URLS=""

# user/group precreated explicitly with fixed uid/gid on purpose.
# It is especially important for rootless containers: in that case entrypoint
# can't do chown and owners of mounted volumes should be configured externally.
# We do that in advance at the begining of Dockerfile before any packages will be
# installed to prevent picking those uid / gid by some unrelated software.
# The same uid / gid (101) is used both for alpine and ubuntu.
ARG DEFAULT_UID="101"
ARG DEFAULT_GID="101"
RUN addgroup -S -g "${DEFAULT_GID}" clickhouse && \
    adduser -S -h "/var/lib/clickhouse" -s /bin/bash -G clickhouse -g "ClickHouse server" -u "${DEFAULT_UID}" clickhouse

RUN arch=${TARGETARCH:-amd64} \
    && cd /tmp \
    && if [ -n "${DIRECT_DOWNLOAD_URLS}" ]; then \
        echo "installing from provided urls with tgz packages: ${DIRECT_DOWNLOAD_URLS}" \
        && for url in $DIRECT_DOWNLOAD_URLS; do \
            echo "Get ${url}" \
            && wget -c -q "$url" \
        ; done \
    else \
        for package in ${PACKAGES}; do \
            echo "Get ${REPOSITORY}/${package}-${VERSION}-${arch}.tgz" \
            && wget -c -q "${REPOSITORY}/${package}-${VERSION}-${arch}.tgz" \
            && wget -c -q "${REPOSITORY}/${package}-${VERSION}-${arch}.tgz.sha512" \
        ; done \
    fi \
    && cat *.tgz.sha512 | sed 's:/output/:/tmp/:' | sha512sum -c \
    && for file in *.tgz; do \
        if [ -f "$file" ]; then \
            echo "Unpacking $file"; \
            tar xvzf "$file" --strip-components=1 -C /; \
        fi \
    ; done \
    && rm /tmp/*.tgz /install -r \
    && chmod +x /entrypoint.sh \
    && apk add --no-cache bash tzdata \
    && cp /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "UTC" > /etc/timezone

ARG DEFAULT_CLIENT_CONFIG_DIR="/etc/clickhouse-client"
ARG DEFAULT_SERVER_CONFIG_DIR="/etc/clickhouse-server"
ARG DEFAULT_DATA_DIR="/var/lib/clickhouse"
ARG DEFAULT_LOG_DIR="/var/log/clickhouse-server"

# we need to allow "others" access to ClickHouse folders, because docker containers
# can be started with arbitrary uids (OpenShift usecase)
RUN mkdir -p \
      "${DEFAULT_DATA_DIR}" \
      "${DEFAULT_LOG_DIR}" \
      "${DEFAULT_CLIENT_CONFIG_DIR}" \
      "${DEFAULT_SERVER_CONFIG_DIR}/config.d" \
      "${DEFAULT_SERVER_CONFIG_DIR}/users.d" \
      /docker-entrypoint-initdb.d \
    && chown clickhouse:clickhouse "${DEFAULT_DATA_DIR}" \
    && chown root:clickhouse "${DEFAULT_LOG_DIR}" \
    && chmod ugo+Xrw -R "${DEFAULT_DATA_DIR}" "${DEFAULT_LOG_DIR}" "${DEFAULT_CLIENT_CONFIG_DIR}" "${DEFAULT_SERVER_CONFIG_DIR}"

VOLUME "${DEFAULT_DATA_DIR}"
EXPOSE 9000 8123 9009

ENTRYPOINT ["/entrypoint.sh"]