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

# Add PHP repository
RUN add-apt-repository ppa:ondrej/php

# Install PHP 8.3 and related extensions
RUN apt-get update -y
RUN apt-get install -y php8.3-fpm
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
RUN git clone -b MOODLE_405_STABLE git://git.moodle.org/moodle.git /var/www/html
RUN git config --global --add safe.directory /var/www/html

# Update PHP settings
RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/8.3/fpm/php.ini
RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/8.3/cli/php.ini
RUN sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' /etc/php/8.3/fpm/php.ini
RUN sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' /etc/php/8.3/cli/php.ini
# RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/8.3/cgi/php.ini

# PHP Sodium
RUN apt update -y
RUN apt install -y libsodium-dev php8.3-dev php-pear
# RUN pecl install -f libsodium
# RUN sed -i -e 's/;extension=sodium/extension=sodium/g' /etc/php/8.3/apache2/php.ini
# RUN sed -i -e 's/;extension=sodium/extension=sodium/g' /etc/php/8.3/cli/php.ini

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer update
RUN composer dump-autoload

## Nodejs
RUN curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
RUN apt-get install -y nodejs
RUN apt-get install -y build-essential
# RUN npm install -g npm@10.9.2
# RUN npm install -g n
# RUN n 22.14.0
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

# Creating phpu_moodledata folder
RUN mkdir /var/www/phpu_moodledata
RUN chown www-data:www-data -R /var/www/phpu_moodledata
RUN find /var/www/phpu_moodledata -type d -exec chmod 0770 {} \;
RUN find /var/www/phpu_moodledata -type f -exec chmod 0660 {} \;

# Nginx configuration
RUN echo "security.limit_extensions = .php" >> /etc/php/8.3/fpm/pool.d/www.conf
COPY moodle.nginx /etc/nginx/sites-available/moodle
RUN ln -s /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/
RUN rm -f /etc/nginx/sites-enabled/default
RUN sed -i -e 's/;clear_env = no/clear_env = no/g' /etc/php/8.3/fpm/pool.d/www.conf

# Install moosh
RUN apt-add-repository ppa:zabuch/ppa
RUN apt-get update -y
RUN apt-get install -y moosh
RUN chown root:www-data -R /usr/bin/moosh
RUN chmod 750 /usr/bin/moosh
RUN mkdir /var/www/.moosh/
# RUN ln -s /usr/bin/moosh /var/www/.moosh/moosh 
RUN chmod 0750 /var/www/.moosh/
RUN find /var/www/.moosh/ -type d -exec chmod 0750 {} \;
RUN find /var/www/.moosh/ -type f -exec chmod 0640 {} \;
RUN chown www-data:www-data -R /var/www/.moosh/

# fix to composer requirement in the phpunit installation
RUN mkdir -p /var/www/.config/composer
RUN find /var/www/.config/ -type d -exec chmod 0750 {} \;
RUN find /var/www/.config/ -type f -exec chmod 0640 {} \;
RUN chown www-data:www-data -R /var/www/.config/
RUN chown www-data:www-data /usr/local/bin/composer

# redis is needed for some plugin in my installation (and not to be installed outside this container)
# but it can be removed, if you don't use. 
RUN apt-get install -y redis-server

# Expose Nginx port
EXPOSE 80

RUN echo "sh -c \"/etc/init.d/php8.3-fpm start && exec nginx -g 'daemon off;' & redis-server\"" >> /cmd.sh
RUN chmod +x /cmd.sh

# Start services
CMD ["sh", "/cmd.sh"]
