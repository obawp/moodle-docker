FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update
RUN apt-get install -y apache2
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:ondrej/php
RUN apt-get update
RUN apt-get install -y php8.2
RUN apt-get install -y php8.2-cli
RUN apt-get install -y php8.2-mysql
RUN apt-get install -y php8.2-xml
RUN apt-get install -y php8.2-mbstring
RUN apt-get install -y php8.2-curl
RUN apt-get install -y php8.2-zip
RUN apt-get install -y php8.2-gd
RUN apt-get install -y php8.2-soap
RUN apt-get install -y php8.2-intl
RUN apt-get install -y php8.2-bcmath
RUN apt-get install -y php8.2-ldap
RUN apt-get install -y php8.2-readline
RUN apt-get install -y php8.2-opcache
RUN apt-get install -y php8.2-redis
RUN apt-get install -y php8.2-pgsql
RUN apt-get install -y php8.2-imap
RUN apt-get install -y mysql-client
RUN apt-get install -y unzip
RUN apt-get install -y nano
RUN apt-get install -y htop
RUN apt-get install -y git
RUN apt-get install -y curl
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite && service apache2 restart

RUN rm -Rf /var/www/html/*

# Set working directory
WORKDIR /var/www/html

# Clone Moodle repository
RUN git clone -b MOODLE_405_STABLE git://git.moodle.org/moodle.git /var/www/html

# Creating moodledata folder
RUN mkdir /var/www/html/moodledata

# Config file
COPY config.php /var/www/html/config.php
COPY php.ini /etc/php/8.2/cli/php.ini

# Setting permissions
# reference: https://docs.moodle.org/405/en/Security_recommendations#Most_secure.2Fparanoid_file_permissions
RUN chown www-data:www-data -R /var/www/html/
RUN chmod -R 0750 /var/www/html
RUN find /var/www/html -type f -exec chmod 0640 {} \;
RUN chown www-data:www-data -R /var/www/html/moodledata
RUN chmod -R 0770 /var/www/html/moodledata
RUN find /var/www/html/moodledata -type f -exec chmod 0660 {} \;

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Moodle dependencies
RUN cd /var/www/html && composer install --no-dev

RUN add-apt-repository main
RUN add-apt-repository universe
RUN add-apt-repository restricted
RUN add-apt-repository multiverse  
RUN apt-get install -y sudo

COPY php.ini /etc/php/8.2/apache2/php.ini
RUN /etc/init.d/apache2 restart

# Expose Apache port
EXPOSE 80

# Start Apache
CMD ["apachectl", "-D", "FOREGROUND"]
