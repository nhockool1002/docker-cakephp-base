#start with our base image (the foundation) - version 7.1.29
FROM php:7.3-apache

COPY src/composer.lock src/composer.json /var/www/html/

WORKDIR /var/www/html

#install all the system dependencies and enable PHP modules 
RUN apt-get update && apt-get install -y \  
      gcc \
      make \
      autoconf \
      libc-dev \
      pkg-config \
      libicu-dev \
      libpq-dev \
      libmcrypt-dev \
      default-mysql-client \
      git \
      zip \
      unzip \
    && rm -r /var/lib/apt/lists/* \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-install \
      intl \
      mbstring \
      pcntl \
      pdo_mysql \
      pdo_pgsql \
      pgsql \
      opcache

RUN pecl install mcrypt-1.0.3
RUN docker-php-ext-enable mcrypt
RUN set -eux; apt-get update; apt-get install -y libzip-dev zlib1g-dev; docker-php-ext-install zip

#install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

ENV COMPOSER_ALLOW_SUPERUSER=1

#set our application folder as an environment variable
ENV APP_HOME /var/www/html

#change uid and gid of apache to docker user uid/gid
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

#change the web_root to laravel /var/www/html/public folder
RUN sed -i -e "s/html/html\/webroot/g" /etc/apache2/sites-enabled/000-default.conf

# enable apache module rewrite
RUN a2enmod rewrite && \
        echo "ServerName localhost" >> /etc/apache2/apache2.conf

#copy source files and run composer
COPY . $APP_HOME

# install all PHP dependencies
RUN composer install --no-interaction

#change ownership of our applications
RUN chown -R www-data:www-data $APP_HOME
