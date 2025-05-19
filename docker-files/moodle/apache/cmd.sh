#!/bin/bash
set -e

# Set timezone
rm /etc/localtime && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

# Export environment variables
printenv | grep -v "no_proxy" >> /etc/environment
export $(cat /etc/environment | xargs)

a2dissite moodle.conf

# Update Nginx configuration to use the specified web port
sed -i "s/Listen 80/Listen $WEB_PORT/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:$WEB_PORT>/" /etc/apache2/sites-available/moodle.conf
sed -i "s/Listen 443/Listen $WEBS_PORT/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:443>/<VirtualHost *:$WEBS_PORT>/" /etc/apache2/sites-available/moodle.conf

# Update Nginx configuration to use the specified domain
sed -i -e "s/moodle.local/$DOMAIN/g" /etc/apache2/sites-available/moodle.conf

# Adding  Non-interactive self-signed Certificate and 10 years expiration
mkdir -p /etc/letsencrypt/live/$DOMAIN/ || true
cd /etc/letsencrypt/live/$DOMAIN/
if [ ! -e /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
    echo "Creating self-signed certificate..."
    openssl req -x509 -newkey rsa:4096 -keyout privkey.pem -out fullchain.pem -sha256 -days 3650 -nodes -subj "/C=$CERT_COUNTRY/ST=$CERT_STATE/L=$CERT_CITY/O=$CERT_ORG/OU=$CERT_ORG_UNIT/CN=$DOMAIN"
else
    echo "Self-signed certificate already exists or not needed."
fi
cd /var/www/html

a2ensite moodle.conf

# Start PHP-FPM service
/etc/init.d/php8.3-fpm start

# Start Cron service
/etc/init.d/cron start

# Start Redis server
redis-server & # do not remove the &

# Start Apache in the foreground
apache2ctl -D FOREGROUND &

# Restart Apache every 12 hours to apply certbot renewal
while true; do
    sleep 12h
    apache2ctl graceful
done
