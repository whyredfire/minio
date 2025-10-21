#!/bin/sh
#
# MinIO Docker entrypoint script
# Based on official MinIO docker-entrypoint.sh
#

# If command starts with an option, prepend minio
if [ "${1}" != "minio" ]; then
    if [ -n "${1}" ]; then
        set -- minio "$@"
    fi
fi

## Look for docker secrets in default documented location.
docker_secrets_env() {
    ACCESS_KEY_FILE="/run/secrets/$MINIO_ROOT_USER_FILE"
    SECRET_KEY_FILE="/run/secrets/$MINIO_ROOT_PASSWORD_FILE"

    if [ -f "$ACCESS_KEY_FILE" ] && [ -f "$SECRET_KEY_FILE" ]; then
        if [ -f "$ACCESS_KEY_FILE" ]; then
            MINIO_ROOT_USER="$(cat "$ACCESS_KEY_FILE")"
            export MINIO_ROOT_USER
        fi
        if [ -f "$SECRET_KEY_FILE" ]; then
            MINIO_ROOT_PASSWORD="$(cat "$SECRET_KEY_FILE")"
            export MINIO_ROOT_PASSWORD
        fi
    fi
}

# su-exec to requested user, if service cannot run as root
# (e.g. docker restarts container with --user flag)
docker_switch_user() {
    if [ -n "${MINIO_USERNAME}" ] && [ -n "${MINIO_GROUPNAME}" ]; then
        if [ -n "${MINIO_UID}" ] && [ -n "${MINIO_GID}" ]; then
            exec chroot --userspec=${MINIO_UID}:${MINIO_GID} / "$@"
        else
            exec chroot --userspec=${MINIO_USERNAME}:${MINIO_GROUPNAME} / "$@"
        fi
    else
        exec "$@"
    fi
}

## Set KMS_SECRET_KEY from docker secrets if provided
docker_kms_encryption_env() {
    KMS_SECRET_KEY_FILE="/run/secrets/$MINIO_KMS_SECRET_KEY_FILE"

    if [ -f "$KMS_SECRET_KEY_FILE" ]; then
        MINIO_KMS_SECRET_KEY="$(cat "$KMS_SECRET_KEY_FILE")"
        export MINIO_KMS_SECRET_KEY
    fi
}

## Set SSE_MASTER_KEY from docker secrets if provided
docker_sse_encryption_env() {
    SSE_MASTER_KEY_FILE="/run/secrets/$MINIO_SSE_MASTER_KEY_FILE"

    if [ -f "$SSE_MASTER_KEY_FILE" ]; then
        MINIO_SSE_MASTER_KEY="$(cat "$SSE_MASTER_KEY_FILE")"
        export MINIO_SSE_MASTER_KEY
    fi
}

# Load docker secrets
docker_secrets_env
docker_kms_encryption_env
docker_sse_encryption_env

# Execute with user switching if needed
docker_switch_user "$@"
