#!/bin/bash

set -e

envsubst '$MYSQL_DATABASE:$MYSQL_USER:$MYSQL_PASSWORD' < /init.sql.template > /docker-entrypoint-initdb.d/init.sql

# echo "Database initialization script created."
# cat /docker-entrypoint-initdb.d/init.sql

exec docker-entrypoint.sh mysqld