#!/bin/sh
set -e

if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set"
  exit 1
fi

# Convert postgresql://user:pass@host/db  →  user:pass@host:5432/db
DB=$(echo "$DATABASE_URL" \
  | sed 's|postgresql://||' \
  | sed 's|postgres://||' \
  | sed 's|\([^/]*\)/\([^?]*\).*|\1:5432/\2|')

# Extract host for readiness check
HOST=$(echo "$DB" | sed 's|.*@||' | sed 's|:.*||')

echo "Waiting for PostgreSQL at $HOST:5432..."
TRIES=0
until nc -z "$HOST" 5432 2>/dev/null; do
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge 30 ]; then
    echo "ERROR: database not reachable after 60s"
    exit 1
  fi
  echo "  retry $TRIES/30 ..."
  sleep 2
done
echo "PostgreSQL is up"

echo "Running migrations..."
/nakama/nakama migrate up --database.address "$DB"

echo "Starting Nakama..."
exec /nakama/nakama \
  --name nakama1 \
  --database.address "$DB" \
  --logger.level INFO \
  --session.token_expiry_sec 7200
