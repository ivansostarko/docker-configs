FROM dunglas/frankenphp:1-php8.3-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends     git unzip curl ca-certificates     librdkafka-dev     && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN set -eux;     install-php-extensions       pdo_mysql       intl       zip       opcache       pcntl       sockets       redis       mongodb       rdkafka
