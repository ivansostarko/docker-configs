# syntax=docker/dockerfile:1.6
ARG NODE_VERSION=20

FROM node:${NODE_VERSION}-alpine AS base
WORKDIR /app

# Non-root user
RUN addgroup -S app && adduser -S app -G app

# --- deps layer ---
FROM base AS deps
COPY package*.json ./
# Use npm ci when lockfile exists; fall back to npm install otherwise.
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

# --- build layer (kept for TS/build use cases) ---
FROM base AS build
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi
COPY . .
# Uncomment if you have a build step (TypeScript, bundling, etc.)
# RUN npm run build

# --- runtime ---
FROM node:${NODE_VERSION}-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./
COPY --from=build /app/server.js ./server.js
COPY --from=build /app/config ./config

# Ensure mount targets exist
RUN mkdir -p /app/config /app/data && chown -R node:node /app

USER node
EXPOSE 3000

CMD ["node", "server.js"]
