# Base image
FROM php:${PHP_APACHE_VERSION}-apache

# ---------------------------
# Arguments for user
# ---------------------------
ARG APP_USER=${APP_USER}
ARG APP_UID=${APP_UID}
ARG APP_GID=${APP_GID}


# ---------------------------
# Configure timezone
# ---------------------------
RUN echo "${TIMEZONE}" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata


# ---------------------------
# Configure UTF8
# ---------------------------
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen  \
    &&  echo "hr_HR.UTF-8 UTF-8" >> /etc/locale.gen \
    &&  locale-gen


# ---------------------------
# Install system dependencies
# ---------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    zip \
    curl \
    supervisor \
    apache2-dev \
    apache2 \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libbz2-dev \
    pkg-config \
    libmagickwand-dev \
    libicu-dev \
    libmcrypt-dev \
    gnupg2 \
    libpq-dev \
    locales \
    apt-utils \
    librdkafka-dev \
    libpcre3-dev \
    libgeoip-dev \
    libtool \
    dh-autoreconf \
    g++ \
    libxslt-dev \
    nano \
    msmtp \
    apt-transport-https \
    doxygen \
    libcurl4-gnutls-dev \
    tar \
    flex \
    bison \
    libyajl-dev \
    ssdeep \
    liblua5.2-dev \
    lsb-release \
    ca-certificates \
    msmtp \
    perl \
    libsodium-dev \
    software-properties-common \
    libjpeg62-turbo-dev \
    && rm -rf /var/lib/apt/lists/*


RUN apt-get update -y

# ---------------------------
# Install Google Page Speed
# ---------------------------
RUN wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
RUN dpkg -i mod-pagespeed-*.deb
RUN rm mod-pagespeed-*.deb
RUN sed -i -e 's/ModPagespeed on/ModPagespeed off/g' /etc/apache2/mods-available/pagespeed.conf


# ---------------------------
# Apache Config
# ---------------------------
ENV APACHE_DOCUMENT_ROOT /var/www/html
RUN mkdir /var/cache/apache-web-cache
RUN chown www-data.www-data /var/cache/apache-web-cache
RUN chmod 755 /var/cache/apache-web-cache

# ---------------------------
# Enable Apache modules
# ---------------------------
RUN a2enmod ssl
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod proxy_http
RUN a2enmod proxy_http2
RUN a2enmod cache
RUN a2enmod cache_disk
RUN a2enmod file_cache
RUN a2enmod cache_socache
RUN a2enmod deflate
RUN a2enmod expires
RUN a2enmod info
RUN a2enmod pagespeed

# ---------------------------
# Install PECL extensions
# ---------------------------
RUN pecl install xdebug
RUN pecl install redis 
RUN pecl install imagick 
RUN pecl install mcrypt
RUN pecl install rdkafka
RUN pecl install apcu
RUN pecl install redis
RUN pecl install -o -f mongodb


# ---------------------------
# Install PHP extensions
# ---------------------------
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install bz2
RUN docker-php-ext-install opcache
RUN docker-php-ext-install intl
RUN docker-php-ext-install zip
RUN docker-php-ext-install fileinfo
RUN docker-php-ext-install calendar
RUN docker-php-ext-install dom
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install soap
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install curl
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install exif
RUN docker-php-ext-install fileinfo
RUN docker-php-ext-install phar
RUN docker-php-ext-install curl
RUN docker-php-ext-install sodium
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ 
RUN docker-php-ext-install gd



# ---------------------------
# Enable PHP extensions
# ---------------------------
RUN docker-php-ext-enable mysqli
RUN docker-php-ext-enable sodium
RUN docker-php-ext-enable mongodb
RUN docker-php-ext-enable apcu
RUN docker-php-ext-enable redis
RUN docker-php-ext-enable rdkafka
RUN docker-php-ext-enable xdebug
RUN docker-php-ext-enable redis 
RUN docker-php-ext-enable imagick
RUN docker-php-ext-enable mcrypt
RUN docker-php-ext-enable gd
RUN docker-php-ext-enable bz2
RUN docker-php-ext-enable opcache
RUN docker-php-ext-enable intl
RUN docker-php-ext-enable zip
RUN docker-php-ext-enable fileinfo
RUN docker-php-ext-enable calendar
RUN docker-php-ext-enable dom
RUN docker-php-ext-enable mbstring
RUN docker-php-ext-enable soap
RUN docker-php-ext-enable bcmath
RUN docker-php-ext-enable curl
RUN docker-php-ext-enable pdo_mysql
RUN docker-php-ext-enable mysqli
RUN docker-php-ext-enable exif
RUN docker-php-ext-enable fileinfo
RUN docker-php-ext-enable phar
RUN docker-php-ext-enable curl


# ---------------------------
# Install Composer
# ---------------------------
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


# ---------------------------
# Supervisor configuration
# ---------------------------
RUN mkdir -p /etc/supervisor/conf.d
COPY ./config/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf



# ---------------------------
# Update default Apache site configuration
# ---------------------------
COPY /config/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./config/php/php.ini /etc/php/${PHP_APACHE_VERSION}/cli/conf.d/php.ini


# ---------------------------
# Set working directory
# ---------------------------
WORKDIR ${APACHE_DOCUMENT_ROOT}


# ---------------------------
# Add user
# ---------------------------
RUN groupadd -g ${APP_GID} ${APP_USER} \
    && useradd -u ${APP_UID} -g ${APP_GID} -m -s /bin/bash ${APP_USER} \
    && chown -R ${APP_USER}:${APP_USER} /var/www/html

RUN chown -R www-data:www-data /var/www/html


# ---------------------------
# Switch to non-root user
# ---------------------------
USER ${APP_USER}


# ---------------------------
# Expose port 80
# ---------------------------
EXPOSE 80

# ---------------------------
# Start Apache in foreground
# ---------------------------
#CMD ["apache2-foreground"]


# ---------------------------
# Start supervisor
# ---------------------------
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]



