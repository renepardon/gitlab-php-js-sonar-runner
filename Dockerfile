FROM php:7.3-fpm-alpine

LABEL maintainer="rene.pardon@boonweb.de"

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php", "-a"]

RUN apk add --update \
    docker \
    libpq \
    libpng-dev \
    jpeg-dev \
    freetype-dev \
    libxrender \
    fontconfig \
    libxext-dev \
    openldap-dev \
    git \
    nodejs nodejs-npm \
    libzip-dev \
    zip \
    curl \
    mysql-client openssh-client icu libpng libjpeg-turbo libmcrypt libmcrypt-dev libsodium pwgen \
    && apk add --no-cache --virtual build-dependencies icu-dev libsodium-dev libxml2-dev freetype-dev libpng-dev \
                                    libjpeg-turbo-dev g++ make autoconf \
    && docker-php-source extract \
    && pecl install xdebug redis libsodium \
    && docker-php-ext-enable xdebug redis sodium \
    && docker-php-source delete \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-install -j$(nproc) pdo_mysql mysqli gd zip ldap pcntl intl \
    && apk del build-dependencies \
    && apk del libmcrypt-dev \
    && rm -rf /tmp/*

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');"

# Install phpunit, the tool that we will use for testing
RUN curl --location --output /usr/local/bin/phpunit https://phar.phpunit.de/phpunit.phar \
    && chmod +x /usr/local/bin/phpunit

RUN curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose
