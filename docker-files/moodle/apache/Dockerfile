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
RUN apt-get update -y
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
RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/8.3/apache2/php.ini
RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/8.3/cli/php.ini
# RUN sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' /etc/php/8.3/apache2/php.ini
# RUN sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' /etc/php/8.3/cli/php.ini

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

# https://docs.moodle.org/405/en/Apache
RUN sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.3/apache2/php.ini
RUN sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.3/cli/php.ini
# RUN echo -e "\nAcceptPathInfo On\n" >> /etc/httpd/httpd.conf
RUN echo "upload_max_filesize = 5000000000" >> /var/www/html/php.ini
RUN echo "post_max_size = 5000000000" >> /var/www/html/php.ini
RUN echo "max_execution_time = 600" >> /var/www/html/php.ini
RUN find /var/www/html -not -path '/var/www/html' -type d -exec ln -s $PWD/php.ini {}/php.ini \;
RUN find /var/www/html -not -path '/var/www/html/php.ini' -type f -iname php.ini  -exec chown root:root {} \;
COPY .htaccess /var/www/html
RUN chmod 640 /var/www/html/.htaccess

# redis is needed for some plugin in my installation (and not to be installed outside this container)
# but it can be removed, if you don't use. 
RUN apt-get install -y redis-server

# Apache config
# COPY moodle.apache /etc/apache2/sites-available/moodle.conf
# RUN a2ensite moodle
# RUN a2dissite 000-default

RUN sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 5000000000/g' /etc/php/8.3/apache2/php.ini
RUN sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 5000000000/g' /etc/php/8.3/cli/php.ini
RUN sed -i -e 's/post_max_size = 8M/post_max_size = 5000000000/g' /etc/php/8.3/apache2/php.ini
RUN sed -i -e 's/post_max_size = 8M/post_max_size = 5000000000/g' /etc/php/8.3/cli/php.ini
RUN sed -i -e 's/max_execution_time = 30/max_execution_time = 600/g' /etc/php/8.3/apache2/php.ini
RUN sed -i -e 's/max_execution_time = 30/max_execution_time = 600/g' /etc/php/8.3/cli/php.ini
RUN /etc/init.d/apache2 restart
RUN echo "apache2ctl -D FOREGROUND & redis-server" >> /cmd.sh
RUN chmod +x /cmd.sh

# Expose Apache port
EXPOSE 80

# Start services
CMD ["sh", "/cmd.sh"]