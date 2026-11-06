
#!/bin/bash

set -Eeuo pipefail

echo "Waiting for MariaDB..."

until mariadb-admin ping \
    -h "${RA_DB_HOST:-db}" \
    -u root \
    -p"${RA_DB_ROOT_PASSWORD}" \
    --silent; do
    sleep 5
done

echo "MariaDB is available."

echo "Checking database initialization..."

TABLE_COUNT=$(mariadb \
    -h "${RA_DB_HOST:-db}" \
    -u root \
    -p"${RA_DB_ROOT_PASSWORD}" \
    -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${RA_DB_NAME}'")

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo "Database already contains tables."
    echo "Skipping initialization."
    exit 0
fi

echo "Importing rAthena SQL schemas..."

mariadb \
    -h "${RA_DB_HOST:-db}" \
    -u root \
    -p"${RA_DB_ROOT_PASSWORD}" \
    "${RA_DB_NAME}" < /rathena/sql-files/main.sql

mariadb \
    -h "${RA_DB_HOST:-db}" \
    -u root \
    -p"${RA_DB_ROOT_PASSWORD}" \
    "${RA_DB_NAME}" < /rathena/sql-files/logs.sql

if [ -f /rathena/sql-files/roulette_default_data.sql ]; then
    mariadb \
        -h "${RA_DB_HOST:-db}" \
        -u root \
        -p"${RA_DB_ROOT_PASSWORD}" \
        "${RA_DB_NAME}" < /rathena/sql-files/roulette_default_data.sql
fi

echo "rAthena database initialization completed."
