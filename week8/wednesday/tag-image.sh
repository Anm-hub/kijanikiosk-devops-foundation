#!/bin/sh
set -eu

VERSION=$(node -p "require('./package.json').version")
GIT_SHA=$(git rev-parse --short=7 HEAD)
IMAGE="ghcr.io/anm-hub/kijanikiosk-payments:${VERSION}-${GIT_SHA}"

docker build --no-cache -f Dockerfile.production -t kijanikiosk-payments:production .
docker tag kijanikiosk-payments:production "$IMAGE"
docker push "$IMAGE"

printf 'Published %s\n' "$IMAGE"
