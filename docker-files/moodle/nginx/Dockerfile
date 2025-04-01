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
RUN apt-get install -y nginx

# Install PHP 7.4 and related extensions
# Add PHP repository
RUN add-apt-repository ppa:ondrej/php

# Install PHP 7.4 and related extensions
RUN apt-get update -y
RUN apt-get install -y php7.4-fpm
RUN apt-get install -y php7.4-cli
RUN apt-get install -y php7.4-mysqlnd
RUN apt-get install -y php7.4-xml
RUN apt-get install -y php7.4-mbstring
RUN apt-get install -y php7.4-curl
RUN apt-get install -y php7.4-zip
RUN apt-get install -y php7.4-gd
RUN apt-get install -y php7.4-soap
RUN apt-get install -y php7.4-intl
RUN apt-get install -y php7.4-bcmath
RUN apt-get install -y php7.4-ldap
RUN apt-get install -y php7.4-readline
RUN apt-get install -y php7.4-opcache
RUN apt-get install -y php7.4-redis
RUN apt-get install -y php7.4-pgsql
RUN apt-get install -y php7.4-imap
RUN apt-get install -y php7.4-exif

# Install Nodejs and build-essential
RUN apt-get install -y nodejs
RUN apt-get install -y build-essential

# fix to "Required locale 'en_AU.UTF-8' is not installed."
RUN apt-get install -y language-pack-en
RUN locale-gen en_AU.UTF-8

# Clean up APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
RUN mkdir -p /var/www/html
RUN rm -Rf /var/www/html/*
WORKDIR /var/www/html

# Clone Moodle repository
RUN git clone -b MOODLE_400_STABLE git://git.moodle.org/moodle.git /var/www/html
RUN git config --global --add safe.directory /var/www/html

RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/7.4/fpm/php.ini
RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/7.4/cli/php.ini
RUN sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' /etc/php/7.4/fpm/php.ini
RUN sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' /etc/php/7.4/cli/php.ini

# PHP Sodium
RUN apt update -y
RUN apt install -y libsodium-dev php7.4-dev php-pear
RUN pecl install -f libsodium
# RUN sed -i -e 's/;extension=sodium/extension=sodium/g' /etc/php/7.4/fpm/php.ini
# RUN sed -i -e 's/;extension=sodium/extension=sodium/g' /etc/php/7.4/cli/php.ini

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN cd /var/www/html && composer install --no-dev

## Nodejs
RUN curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
RUN apt-get install -y nodejs
RUN apt-get install -y build-essential
RUN npm install -g npm@8.19.4
RUN npm install -g n
RUN n 16.20.2
RUN npm i
    
# Setting permissions
RUN chown www-data:www-data -R /var/www/html/
RUN find /var/www/html -type d -exec chmod 0750 {} \;
RUN find /var/www/html -type f -exec chmod 0640 {} \;

# Creating moodledata folder
RUN mkdir /var/www/moodledata
RUN chown www-data:www-data -R /var/www/moodledata
RUN find /var/www/moodledata -type d -exec chmod 0770 {} \;
RUN find /var/www/moodledata -type f -exec chmod 0660 {} \;

# Install moosh
RUN apt-add-repository ppa:zabuch/ppa
RUN apt-get update -y
RUN apt-get install -y moosh
RUN chown root:www-data -R /usr/bin/moosh
RUN chmod 750 /usr/bin/moosh
RUN mkdir /var/www/.moosh/
# RUN ln -s /usr/bin/moosh /var/www/.moosh/moosh 
RUN chmod 0640 -R /var/www/.moosh/
RUN chown root:www-data -R /var/www/.moosh/

# fix to composer requirement in the phpunit installation
RUN mkdir /var/www/.config/
RUN ln -s /usr/local/bin/composer /var/www/.config/composer 
RUN chmod 0640 -R /var/www/.config/
RUN chown root:www-data -R /var/www/.config/


# Nginx configuration
# https://docs.moodle.org/400/en/Nginx
RUN echo "security.limit_extensions = .php" >> /etc/php/7.4/fpm/pool.d/www.conf
COPY moodle.nginx /etc/nginx/sites-available/moodle
RUN ln -s /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/
RUN rm -f /etc/nginx/sites-enabled/default
RUN sed -i -e 's/;clear_env = no/clear_env = no/g' /etc/php/7.4/fpm/pool.d/www.conf

# Expose Nginx port

EXPOSE 80

RUN echo "sh -c \"/etc/init.d/php7.4-fpm start && exec nginx -g 'daemon off;'\"" >> /cmd.sh

# Start services
CMD ["sh", " /cmd.sh"]
