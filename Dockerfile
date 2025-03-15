# Use an official PHP image as a base
FROM php:8.3-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    nano vim \
    ssmtp \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libgmp-dev \
    zip \
    unzip \
    mariadb-client \
    git \
    cron \
    gettext \  
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install pdo pdo_mysql zip exif intl bcmath gmp

# Copy the custom php.ini
COPY custom-php.ini /usr/local/etc/php/conf.d/uploads.ini

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Enable Apache mod_headers
RUN a2enmod headers

# Set working directory
WORKDIR /var/www/html

# Copy custom Apache configuration
COPY ./apache-config.conf /etc/apache2/sites-available/000-default.conf

# Copy the ssmtp template files
COPY ssmtp.conf.template /etc/ssmtp/ssmtp.conf.template
COPY revaliases.template /etc/ssmtp/revaliases.template

# Pass build arguments for ssmtp configuration
ARG SSMTP_ROOT
ARG SSMTP_MAILHUB
ARG SSMTP_AUTHUSER
ARG SSMTP_AUTHPASS
ARG SSMTP_USESTARTTLS
ARG SSMTP_FROMLINEOVERRIDE
ARG REVALIASES_ROOT
ARG REVALIASES_WWWDATA

# Set environment variables for runtime
ENV SSMTP_ROOT=${SSMTP_ROOT} \
    SSMTP_MAILHUB=${SSMTP_MAILHUB} \
    SSMTP_AUTHUSER=${SSMTP_AUTHUSER} \
    SSMTP_AUTHPASS=${SSMTP_AUTHPASS} \
    SSMTP_USESTARTTLS=${SSMTP_USESTARTTLS} \
    SSMTP_FROMLINEOVERRIDE=${SSMTP_FROMLINEOVERRIDE} \
    REVALIASES_ROOT=${REVALIASES_ROOT} \
    REVALIASES_WWWDATA=${REVALIASES_WWWDATA}

# Add Hubzilla cron job
RUN echo "* * * * * www-data cd /var/www/html; php Zotlabs/Daemon/Master.php Cron > /dev/null 2>&1" >> /etc/crontab

# Add startup script
COPY startup.sh /usr/local/bin/startup.sh

# Expose port 80
EXPOSE 80

# Start cron and Apache in the foreground
CMD ["startup.sh"]

