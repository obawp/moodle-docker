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
RUN apt-get install -y iputils-ping
RUN apt-get install -y apache2

# Add PHP repository
RUN add-apt-repository ppa:ondrej/php

# Install PHP 8.3 and related extensions
RUN apt-get update -y
RUN apt-get install -y php8.3
RUN apt-get install libapache2-mod-fcgid 
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

# Install clamav
RUN apt-get install -y clamav clamav-daemon

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

# Add build argument to choose between moodle and iomad
ARG IOMAD

# Conditionally clone Moodle or Iomad
RUN if [ "$IOMAD" = "true" ]; then \
      git clone -b IOMAD_405_STABLE https://github.com/iomad/iomad.git /var/www/html ; \
    else \
      git clone -b MOODLE_405_STABLE git://git.moodle.org/moodle.git /var/www/html ; \
    fi
RUN git config --global --add safe.directory /var/www/html


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

COPY .htaccess /var/www/html
RUN chmod 640 /var/www/html/.htaccess

# redis is needed for some plugin in my installation (and not to be installed outside this container)
# but it can be removed, if you don't use. 
RUN apt-get install -y redis-server

# install cron
RUN apt-get install -y tzdata
RUN apt-get install -y cron

# creating php,ini in all folders
RUN touch /var/www/html/php.ini

# enable below for ionos
# RUN find /var/www/html -not -path '/var/www/html' -type d -exec ln -s $PWD/php.ini {}/php.ini \;
# RUN find /var/www/html -not -path '/var/www/html/php.ini' -type f -iname php.ini  -exec chown root:root {} \;

# cron configuration
RUN echo '* * * * * www-data /usr/bin/php /var/www/html/admin/cli/cron.php &> /var/log/moodle_cron.log' > /etc/cron.d/moodle
RUN chmod 0644 /etc/cron.d/moodle
RUN touch /var/log/cron.log
RUN crontab /etc/cron.d/moodle

# php.ini configuration
RUN echo "upload_max_filesize = 500M" > /var/www/html/php.ini && \
echo "post_max_size = 500M" >> /var/www/html/php.ini && \
echo "max_execution_time = 600" >> /var/www/html/php.ini && \
echo "max_input_vars = 10000" >> /var/www/html/php.ini && \
echo "zlib.output_compression = on" >> /var/www/html/php.ini && \
echo "zlib.output_compression_level = -1" >> /var/www/html/php.ini

# Update PHP settings
RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/8.3/fpm/php.ini && \
    sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 500M/g' /etc/php/8.3/fpm/php.ini && \
    sed -i -e 's/post_max_size = 8M/post_max_size = 500M/g' /etc/php/8.3/fpm/php.ini && \
    sed -i -e 's/max_execution_time = 30/max_execution_time = 600/g' /etc/php/8.3/fpm/php.ini && \
    sed -i -e 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.3/fpm/php.ini && \
    # enable below for ionos (not tested). If enabled, this makes PATH_INFO not work
    # sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.3/fpm/php.ini && \ 
    sed -i -e 's/variables_order = "GPCS"/variables_order = "EGPCS"/g' /etc/php/8.3/fpm/php.ini
RUN sed -i -e 's/;max_input_vars = 1000/max_input_vars = 10000/g' /etc/php/8.3/cli/php.ini && \
    sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 500M/g' /etc/php/8.3/cli/php.ini && \
    sed -i -e 's/post_max_size = 8M/post_max_size = 500M/g' /etc/php/8.3/cli/php.ini && \
    sed -i -e 's/max_execution_time = 30/max_execution_time = 600/g' /etc/php/8.3/cli/php.ini && \
    sed -i -e 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.3/cli/php.ini && \
    # enable below for ionos (not tested). If enabled, this makes PATH_INFO not work
    # sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.3/cli/php.ini && \
    sed -i -e 's/variables_order = "GPCS"/variables_order = "EGPCS"/g' /etc/php/8.3/cli/php.ini

# php-fpm configuration
RUN echo "security.limit_extensions = .php" >> /etc/php/8.3/fpm/pool.d/www.conf
RUN sed -i -e 's/;clear_env = no/clear_env = no/g' /etc/php/8.3/fpm/pool.d/www.conf

# Adding  Non-interactive self-signed Certificate and 10 years expiration
WORKDIR /etc/letsencrypt/live/moodle.local/
RUN openssl req -x509 -newkey rsa:4096 -keyout privkey.pem -out fullchain.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=moodle.local"
WORKDIR /var/www/html

# Copy custom Apache configuration file
COPY moodle.conf /etc/apache2/sites-available/moodle.conf
RUN a2ensite moodle.conf
RUN a2dissite 000-default.conf

# Enable Apache modules
RUN a2enmod rewrite
RUN a2enmod proxy_fcgi setenvif
RUN a2enconf php8.3-fpm
RUN a2enmod ssl
RUN a2enmod headers

RUN echo "ServerName moodle.local" > /etc/apache2/conf-available/servername.conf
RUN /etc/init.d/apache2 stop

COPY cmd.sh /cmd.sh
RUN chmod +x /cmd.sh

# Start services
CMD ["sh", "/cmd.sh"]
