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

echo "Running migrations (will retry until DB is ready)..."
TRIES=0
until /nakama/nakama migrate up --database.address "$DB" 2>&1; do
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge 15 ]; then
    echo "ERROR: migrations failed after 15 attempts"
    exit 1
  fi
  echo "  DB not ready, retry $TRIES/15 in 5s..."
  sleep 5
done

echo "Migrations done. Starting Nakama..."
exec /nakama/nakama \
  --name nakama1 \
  --database.address "$DB" \
  --logger.level INFO \
  --session.token_expiry_sec 7200
