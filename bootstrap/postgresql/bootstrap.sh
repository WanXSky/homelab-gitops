#!/bin/sh

set -eu

echo "[1/4] Waiting for PostgreSQL..."

until PGPASSWORD="$POSTGRES_PASSWORD" \
psql \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  -d postgres \
  -c '\q' >/dev/null 2>&1
do
  sleep 2
done

echo "[✓] PostgreSQL Connected."

export PGPASSWORD="$POSTGRES_PASSWORD"

echo "[2/4] Creating role if not exists..."

psql \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  -d postgres <<EOF

DO
\$\$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = '${APP_DB_USER}'
    ) THEN

        CREATE ROLE ${APP_DB_USER}
        LOGIN
        PASSWORD '${APP_DB_PASSWORD}';

    END IF;
END
\$\$;

EOF

echo "[✓] Role ready."

echo "[3/4] Creating database if not exists..."

psql \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  -d postgres <<EOF

SELECT 'CREATE DATABASE ${APP_DB_NAME}'
WHERE NOT EXISTS (
    SELECT
    FROM pg_database
    WHERE datname = '${APP_DB_NAME}'
)\gexec

EOF

echo "[✓] Database ready."

echo "[4/4] Granting privileges..."

psql \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  -d postgres <<EOF

GRANT ALL PRIVILEGES
ON DATABASE ${APP_DB_NAME}
TO ${APP_DB_USER};

ALTER DATABASE ${APP_DB_NAME}
OWNER TO ${APP_DB_USER};

EOF

echo "[✓] Privileges granted."

echo ""
echo "========================================"
echo " PostgreSQL Bootstrap Complete 🎉"
echo "========================================"
echo "Database : ${APP_DB_NAME}"
echo "User     : ${APP_DB_USER}"
echo ""
