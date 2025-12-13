# syntax=docker/dockerfile:1

FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

# Add minimal tools for healthcheck
RUN apk add --no-cache wget

# Copy production dependencies
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Drop privileges
USER node

EXPOSE 3000
CMD ["node", "src/index.js"]
