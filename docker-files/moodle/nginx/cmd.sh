#!/bin/bash
set -e

# Set VARIABLE to default value if not already set
: "${TZ:=America/Sao_Paulo}"
: "${WEB_PORT:=80}"
: "${WEBS_PORT:=443}"
: "${DOMAIN:=moodle.local}"

# Export environment variables - If you remove this line the cron (and cli commands) may not work.
printenv | grep -v "no_proxy" >> /etc/environment
export $(cat /etc/environment | xargs)

# Set timezone
rm /etc/localtime && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

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
/etc/init.d/php8.3-fpm start & # do not remove the &

# Start Cron service
/etc/init.d/cron start & # do not remove the &

# Start Redis server
redis-server & # do not remove the &

# Start Nginx in the foreground
exec nginx -g 'daemon off;' &

# Restart Nginx every 12 hours to certbot renewal
while true; do
    sleep 12h
    nginx -s reload
done
