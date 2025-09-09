#!/bin/bash
set -e

# Set VARIABLE to default value if not already set
: "${TZ:=America/Sao_Paulo}"
: "${WEB_PORT:=80}"
: "${WEBS_PORT:=443}"
: "${DOMAIN:=moodle.local}"
: "${ENABLE_CRON:=true}"

: "${WEBSERVER_MEMORY:=512M}"
: "${WEBSERVER_TIMEOUT:=600}"

: "${PHP_PM_MODEL:=dynamic}"
: "${PHP_PM_MAX_CHILDREN:=100}"
: "${PHP_PM_START_SERVERS:=20}"
: "${PHP_PM_MIN_SPARE:=10}"
: "${PHP_PM_MAX_SPARE:=30}"
: "${PHP_PM_MAX_REQUESTS:=1000}"

: "${PHP_MEMORY_LIMIT:=512M}"
: "${PHP_OPCACHE_ENABLE:=1}"
: "${PHP_OPCACHE_MEMORY:=256}"
: "${PHP_OPCACHE_STRINGS:=16}"
: "${PHP_OPCACHE_FILES:=20000}"
: "${PHP_OPCACHE_REVALIDATE:=2}"
: "${PHP_OPCACHE_SHUTDOWN:=1}"

sed -i -e "s/proxy_send_timeout 600;/proxy_send_timeout $WEBSERVER_TIMEOUT;/g" /etc/nginx/sites-available/moodle
sed -i -e "s/proxy_read_timeout 600;/proxy_read_timeout $WEBSERVER_TIMEOUT;/g" /etc/nginx/sites-available/moodle
sed -i -e "s/fastcgi_send_timeout 600;/fastcgi_send_timeout $WEBSERVER_TIMEOUT;/g" /etc/nginx/sites-available/moodle
sed -i -e "s/fastcgi_read_timeout 600;/fastcgi_read_timeout $WEBSERVER_TIMEOUT;/g" /etc/nginx/sites-available/moodle

# Update PHP-FPM pool config
sed -i -e "s/^pm = dynamic/pm = ${PHP_PM_MODEL}/g" /etc/php/8.3/fpm/pool.d/www.conf
sed -i -e "s/^pm.max_children = 50/pm.max_children = ${PHP_PM_MAX_CHILDREN}/g" /etc/php/8.3/fpm/pool.d/www.conf
sed -i -e "s/^pm.start_servers = 10/pm.start_servers = ${PHP_PM_START_SERVERS}/g" /etc/php/8.3/fpm/pool.d/www.conf
sed -i -e "s/^pm.min_spare_servers = 5/pm.min_spare_servers = ${PHP_PM_MIN_SPARE}/g" /etc/php/8.3/fpm/pool.d/www.conf
sed -i -e "s/^pm.max_spare_servers = 20/pm.max_spare_servers = ${PHP_PM_MAX_SPARE}/g" /etc/php/8.3/fpm/pool.d/www.conf
sed -i -e "s/^pm.max_requests = 500/pm.max_requests = ${PHP_PM_MAX_REQUESTS}/g" /etc/php/8.3/fpm/pool.d/www.conf

# Update php.ini (FPM and CLI)
for php_ini in /etc/php/8.3/fpm/php.ini /etc/php/8.3/cli/php.ini; do
  sed -i -e "s/^memory_limit = 256M/memory_limit = ${WEBSERVER_MEMORY}/g" "$php_ini"
  sed -i -e "s/^max_execution_time = 600/max_execution_time = $WEBSERVER_TIMEOUT/g" "$php_ini"
  sed -i -e "s/^default_socket_timeout = 60/default_socket_timeout = $WEBSERVER_TIMEOUT/g" "$php_ini"
  sed -i -e "s/^opcache.enable = 1/opcache.enable = ${PHP_OPCACHE_ENABLE}/g" "$php_ini"
  sed -i -e "s/^opcache.memory_consumption = 128/opcache.memory_consumption = ${PHP_OPCACHE_MEMORY}/g" "$php_ini"
  sed -i -e "s/^opcache.interned_strings_buffer = 8/opcache.interned_strings_buffer = ${PHP_OPCACHE_STRINGS}/g" "$php_ini"
  sed -i -e "s/^opcache.max_accelerated_files = 10000/opcache.max_accelerated_files = ${PHP_OPCACHE_FILES}/g" "$php_ini"
  sed -i -e "s/^opcache.revalidate_freq = 0/opcache.revalidate_freq = ${PHP_OPCACHE_REVALIDATE}/g" "$php_ini"
  sed -i -e "s/^opcache.fast_shutdown = 1/opcache.fast_shutdown = ${PHP_OPCACHE_SHUTDOWN}/g" "$php_ini"
done

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

# Start Cron service if ENABLE_CRON is set to true
if [ "${ENABLE_CRON}" = "true" ]; then
    /etc/init.d/cron start & # do not remove the &
fi

# Start Redis server
redis-server & # do not remove the &

# Start Nginx in the foreground
exec nginx -g 'daemon off;' &

# Restart Nginx every 12 hours to certbot renewal
while true; do
    sleep 12h
    nginx -s reload
done
