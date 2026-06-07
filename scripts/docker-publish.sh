#!/usr/bin/env bash
set -euo pipefail

DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-${1:-pop2bubble}}"
IMAGE_NAME="${IMAGE_NAME:-${2:-accommodation-reservation}}"
TAG="${TAG:-${3:-latest}}"
PUSH="${PUSH:-true}"
SKIP_BUILD="${SKIP_BUILD:-false}"
FULL_IMAGE="${IMAGE:-docker.io/${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${TAG}}"

if [[ "${FULL_IMAGE}" =~ [A-Z] ]]; then
  echo "Docker image names must be lowercase: ${FULL_IMAGE}" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker CLI is not available. Rebuild the Dev Container so the docker-in-docker feature is installed." >&2
  exit 1
fi

if [[ "${SKIP_BUILD}" != "true" ]]; then
  echo "==> Docker build: ${FULL_IMAGE}"
  docker build -t "${FULL_IMAGE}" .
fi

if [[ "${PUSH}" != "true" ]]; then
  echo "Done: ${FULL_IMAGE}"
  exit 0
fi

echo "==> Docker Hub login: ${DOCKERHUB_USERNAME}"
if [[ -n "${DOCKERHUB_TOKEN:-}" ]]; then
  printf '%s' "${DOCKERHUB_TOKEN}" | docker login docker.io -u "${DOCKERHUB_USERNAME}" --password-stdin
elif [[ -t 0 ]]; then
  docker login docker.io -u "${DOCKERHUB_USERNAME}"
else
  echo "DOCKERHUB_TOKEN is required for non-interactive Docker Hub login." >&2
  exit 1
fi

echo "==> Docker push: ${FULL_IMAGE}"
docker push "${FULL_IMAGE}"

echo "Done: ${FULL_IMAGE}"
