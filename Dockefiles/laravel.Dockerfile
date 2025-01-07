# Use PHP with Apache as the base image
FROM php:8.2-apache

# Install PHP extensions

RUN apt-get update \
    && apt-get install -y \
        curl \
        nano \
        libjpeg-dev \
        libfreetype6-dev \
        zip \
        unzip \
        libonig-dev \
        libxml2-dev \
        libzip-dev \
        libpq-dev

# Enable Apache mod_rewrite for URL rewriting
RUN a2enmod rewrite

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql  zip


# Configure Apache DocumentRoot to point to Laravel's public directory
# and update Apache configuration files
# Adjust Apache configuration such that the service is bound to port 8080 instead of port 80 to avoid the requirement to run as 'root'
RUN sed -i.bak 's/Listen 80/Listen 9000/' /etc/apache2/ports.conf

RUN sed -i.bak 's/<VirtualHost \*:80>/<VirtualHost \*:9000>/' /etc/apache2/sites-available/000-default.conf

# Copy the application code
COPY . /var/www/html

WORKDIR /var/www/html


# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install project dependencies
RUN composer install

# Set permissions
#RUN chown -R www-data:www-data /app/web
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

RUN  chmod -R 777 /var/www/html/storage
RUN  chmod -R 777 /var/www/html/bootstrap
USER www-data

EXPOSE 9000
