FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y software-properties-common
RUN apt-get install -y sudo
RUN apt-get install -y mysql-client
RUN apt-get install -y unzip
RUN apt-get install -y nano
RUN apt-get install -y htop
RUN apt-get install -y git
RUN apt-get install -y curl
RUN apt-get install -y apache2

# Add PHP repository
RUN add-apt-repository ppa:ondrej/php

# Install PHP 8.3 and related extensions
RUN apt-get install -y php8.3
RUN apt-get install -y php8.3-cli
RUN apt-get install -y php8.3-mysqlnd
RUN apt-get install -y php8.3-xml
RUN apt-get install -y php8.3-mbstring
RUN apt-get install -y php8.3-curl
RUN apt-get install -y php8.3-zip
RUN apt-get install -y php8.3-gd
RUN apt-get install -y php8.3-soap
RUN apt-get install -y php8.3-intl
RUN apt-get install -y php8.3-bcmath
RUN apt-get install -y php8.3-ldap
RUN apt-get install -y php8.3-readline
RUN apt-get install -y php8.3-opcache
RUN apt-get install -y php8.3-redis
RUN apt-get install -y php8.3-pgsql
RUN apt-get install -y php8.3-imap

# Enable Apache modules
RUN a2enmod rewrite
RUN a2enmod php8.3

# Install Nodejs and build-essential
RUN apt-get install -y nodejs
RUN apt-get install -y build-essential

# Clean up APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
RUN mkdir -p /var/www/html
RUN rm -Rf /var/www/html/*
WORKDIR /var/www/html

# Clone Moodle repository
RUN git clone -b MOODLE_405_STABLE git://git.moodle.org/moodle.git /var/www/html

# Update PHP settings
RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/8.3/apache2/php.ini
RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/8.3/cli/php.ini

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer update
RUN composer dump-autoload

## Nodejs
RUN curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
RUN apt-get install -y nodejs
RUN apt-get install -y build-essential
RUN npm i
    
# Setting permissions
RUN chown www-data:www-data -R /var/www/html/
RUN chmod -R 0750 /var/www/html
RUN find /var/www/html -type f -exec chmod 0640 {} \;

# Creating moodledata folder
RUN mkdir /var/www/moodledata
RUN chown www-data:www-data -R /var/www/moodledata
RUN chmod -R 0770 /var/www/moodledata
RUN find /var/www/moodledata -type f -exec chmod 0660 {} \;

# Apache config
# COPY moodle.apache /etc/apache2/sites-available/moodle.conf
# RUN a2ensite moodle
# RUN a2dissite 000-default

# Expose Apache port
EXPOSE 80

# Start services
CMD ["apache2ctl", "-D", "FOREGROUND"]