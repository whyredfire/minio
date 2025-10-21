# MinIO Dockerfile based on official build process
# Supports building from source for any release version

ARG MINIO_VERSION=latest
ARG TARGETARCH

# Build stage - compile MinIO from source
FROM golang:1.24-alpine AS builder

ARG MINIO_VERSION
ARG TARGETARCH

WORKDIR /workspace

# Install build dependencies
RUN apk add --no-cache git make ca-certificates

# Clone MinIO source code at the specified version
RUN git clone https://github.com/minio/minio.git . && \
    if [ "$MINIO_VERSION" != "latest" ]; then \
        echo "Checking out version: $MINIO_VERSION" && \
        git checkout ${MINIO_VERSION}; \
    else \
        echo "Building from latest master"; \
    fi

# Build MinIO binary
RUN CGO_ENABLED=0 go build -trimpath \
    -ldflags "-s -w" \
    -o /usr/bin/minio

# Verify the binary works
RUN /usr/bin/minio --version

# Runtime stage - minimal image with MinIO binary
FROM registry.access.redhat.com/ubi9/ubi-micro:latest

ARG MINIO_VERSION
ARG TARGETARCH

LABEL org.opencontainers.image.source="https://github.com/minio/minio"
LABEL org.opencontainers.image.version="${MINIO_VERSION}"
LABEL org.opencontainers.image.description="MinIO Object Storage - Built from source"
LABEL org.opencontainers.image.authors="MinIO, Inc."
LABEL org.opencontainers.image.vendor="MinIO, Inc."
LABEL org.opencontainers.image.licenses="AGPL-3.0"

# Copy MinIO binary and official docker scripts from builder
COPY --from=builder /usr/bin/minio /usr/bin/minio
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /workspace/dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

# Set executable permissions
RUN chmod +x /usr/bin/minio /usr/bin/docker-entrypoint.sh

# Environment variables for MinIO configuration
ENV MINIO_ROOT_USER="" \
    MINIO_ROOT_PASSWORD="" \
    MINIO_CONFIG_ENV_FILE=""

# Expose MinIO ports
# 9000: S3 API
# 9001: Web Console
EXPOSE 9000 9001

# Data volume
VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["minio"]
