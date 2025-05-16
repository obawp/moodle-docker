#!/bin/bash
set -e

# Set timezone
rm /etc/localtime && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

# Export environment variables
printenv | grep -v "no_proxy" >> /etc/environment
export $(cat /etc/environment | xargs)

# Update Nginx configuration to use the specified web port
sed -i -e "s/listen 80;/listen $WEB_PORT;/g" /etc/nginx/sites-available/moodle
sed -i -e "s/listen 443/listen $WEBS_PORT/g" /etc/nginx/sites-available/moodle
sed -i -e "s/listen [::]:/listen [::]:$WEBS_PORT/g" /etc/nginx/sites-available/moodle

# Update Nginx configuration to use the specified domain
sed -i -e "s/moodle.local/$DOMAIN/g" /etc/nginx/sites-available/moodle

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

# Start PHP-FPM service
/etc/init.d/php8.3-fpm start

# Start Cron service
/etc/init.d/cron start

# Start Redis server
redis-server & # do not remove the &

# Start Nginx in the foreground
exec nginx -g 'daemon off;' &

# Restart Nginx every 12 hours to certbot renewal
while true; do
    sleep 12h
    nginx -s reload
done
