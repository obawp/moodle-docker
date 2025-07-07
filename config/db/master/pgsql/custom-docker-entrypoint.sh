#!/bin/bash

set -e

envsubst '$POSTGRES_DB:$POSTGRES_USER:$POSTGRES_PASSWORD' < /init.sql.template > /docker-entrypoint-initdb.d/init.sql

# echo "Database initialization script created."
# cat /docker-entrypoint-initdb.d/init.sql

exec docker-entrypoint.sh postgres