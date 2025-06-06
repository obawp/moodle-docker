#!/bin/bash

set -e

envsubst '$MARIADB_DATABASE:$MARIADB_USER:$MARIADB_PASSWORD' < /init.sql.template > /docker-entrypoint-initdb.d/init.sql

# echo "Database initialization script created."
# cat /docker-entrypoint-initdb.d/init.sql

exec docker-entrypoint.sh mariadbd