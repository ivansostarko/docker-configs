FROM php:8.3-fpm-alpine

# Install minimal tooling for healthchecks + common extensions
RUN apk add --no-cache \
      bash \
      curl \
      fcgi \
      procps \
      tzdata \
    && docker-php-ext-install opcache

# Create a non-root user (optional)
RUN addgroup -g 1000 -S app && adduser -u 1000 -S app -G app

WORKDIR /var/www/html
