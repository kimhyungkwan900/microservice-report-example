#!/usr/bin/env bash
set -euo pipefail

DOCKERHUB_USERNAME="${1:-pop2bubble}"
IMAGE_NAME="${2:-accommodation-reservation}"
TAG="${3:-latest}"
FULL_IMAGE="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${TAG}"

echo "==> Podman build: ${FULL_IMAGE}"
podman build -t "${FULL_IMAGE}" .

echo "==> Docker Hub login (if needed)"
podman login docker.io

echo "==> Podman push: ${FULL_IMAGE}"
podman push "${FULL_IMAGE}"

echo "Done: ${FULL_IMAGE}"
