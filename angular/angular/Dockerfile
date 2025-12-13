# Production build + Nginx static serving.
# This Dockerfile is intentionally resilient to Angular dist path differences by:
# - building into /workspace/dist/**
# - locating index.html and copying its directory into /out
#
# Build args:
# - ANGULAR_BUILD_CONFIGURATION: typically "production"
# - BASE_HREF: base href for deployments under subpaths (e.g. "/app/")
FROM node:22-alpine AS builder

WORKDIR /workspace
RUN apk add --no-cache bash

COPY ./app/package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY ./app ./

ARG ANGULAR_BUILD_CONFIGURATION=production
ARG BASE_HREF=/

# Build (supports typical Angular CLI builds)
RUN npx ng version >/dev/null 2>&1 || npm i -g @angular/cli
RUN npx ng build --configuration="${ANGULAR_BUILD_CONFIGURATION}" --base-href="${BASE_HREF}"

# Normalize output into /out (directory containing index.html)
RUN set -euo pipefail;     idx="$(find dist -name index.html -print -quit)";     if [ -z "${idx}" ]; then       echo "ERROR: Could not find dist/**/index.html. Check your Angular build output.";       echo "dist tree:"; find dist -maxdepth 4 -type f | head -n 200;       exit 1;     fi;     outdir="$(dirname "${idx}")";     mkdir -p /out;     cp -a "${outdir}/." /out/

FROM nginx:1.27-alpine

# Replace default config with ours (mounted via docker compose config)
# Copy normalized build output
COPY --from=builder /out/ /usr/share/nginx/html/
