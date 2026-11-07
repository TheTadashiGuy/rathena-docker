
#!/bin/bash

set -Eeuo pipefail

DB_HOST="${RA_DB_HOST:-db}"
MAIN_DB="${RA_DB_NAME:-ragnarok}"
LOG_DB="log"

echo "Waiting for MariaDB..."

until mariadb \
    -h "$DB_HOST" \
    -u root \
    -p"${RA_DB_ROOT_PASSWORD}" \
    -e "SELECT 1" >/dev/null 2>&1; do
    sleep 5
done

echo "MariaDB is available."

# Verify required SQL files.
for file in main.sql logs.sql; do
    if [ ! -s "/rathena/sql-files/$file" ]; then
        echo "ERROR: Missing or empty SQL file: $file" >&2
        exit 1
    fi
done

echo "Checking database initialization..."

MAIN_TABLES=$(mariadb \
    -h "$DB_HOST" \
    -u root \
    -p"${RA_DB_ROOT_PASSWORD}" \
    -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${MAIN_DB}'")

LOG_TABLES=$(mariadb \
    -h "$DB_HOST" \
    -u root \
    -p"${RA_DB_ROOT_PASSWORD}" \
    -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${LOG_DB}'")

if [ "$MAIN_TABLES" -gt 0 ] && [ "$LOG_TABLES" -gt 0 ]; then
    echo "Both databases already contain tables."
    echo "Skipping initialization."
    exit 0
fi

if [ "$MAIN_TABLES" -gt 0 ] || [ "$LOG_TABLES" -gt 0 ]; then
    echo "ERROR: Partial database initialization detected." >&2
    echo "Main database tables: $MAIN_TABLES" >&2
    echo "Log database tables: $LOG_TABLES" >&2
    echo "Refusing to import over an existing database." >&2
    exit 1
fi

echo "Verifying database user..."

mariadb -h "$DB_HOST" -u root -p"${RA_DB_ROOT_PASSWORD}" \
    -Nse "SELECT User FROM mysql.user WHERE User='${RA_DB_USER}' LIMIT 1" \
    | grep -qx "$RA_DB_USER" || {
        echo "ERROR: Database user ${RA_DB_USER} does not exist." >&2
        exit 1
    }

echo "Creating log database..."

mariadb -h "$DB_HOST" -u root -p"${RA_DB_ROOT_PASSWORD}" \
    -e "CREATE DATABASE IF NOT EXISTS \`${LOG_DB}\`;"

echo "Granting database permissions..."

mariadb -h "$DB_HOST" -u root -p"${RA_DB_ROOT_PASSWORD}" \
    -e "GRANT ALL PRIVILEGES ON \`${MAIN_DB}\`.* TO '${RA_DB_USER}'@'%';
        GRANT ALL PRIVILEGES ON \`${LOG_DB}\`.* TO '${RA_DB_USER}'@'%';
        FLUSH PRIVILEGES;"

echo "Importing main.sql..."

mariadb \
    -h "$DB_HOST" \
    -u root \
    -p"${RA_DB_ROOT_PASSWORD}" \
    "$MAIN_DB" < /rathena/sql-files/main.sql

echo "Importing logs.sql..."

mariadb \
    -h "$DB_HOST" \
    -u root \
    -p"${RA_DB_ROOT_PASSWORD}" \
    "$LOG_DB" < /rathena/sql-files/logs.sql

if [ -s /rathena/sql-files/roulette_default_data.sql ]; then
    echo "Importing roulette default data..."

    mariadb \
        -h "$DB_HOST" \
        -u root \
        -p"${RA_DB_ROOT_PASSWORD}" \
        "$MAIN_DB" < /rathena/sql-files/roulette_default_data.sql
fi

echo "Database initialization completed successfully."
