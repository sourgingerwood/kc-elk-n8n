#!/bin/bash

TARGET_FILE=".env"

echo "🚀 Starting Pinggy tunnel..."

# Retry logic
MAX_RETRIES=10
RETRY_DELAY=5

while true; do
  TMP_FILE=$(mktemp)

  # Start Pinggy in background with web debugger
  ssh -p 443 -R0:localhost:5678 -L4300:localhost:4300 \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=30 \
    -T a.pinggy.io > "$TMP_FILE" 2>&1 &

  PINGGY_PID=$!

  sleep 7  # Let it initialize

  # Wait for Web Debugger to respond
  if curl -s http://localhost:4300/urls > /dev/null; then
    NEW_DOMAIN=$(curl -s http://localhost:4300/urls | jq -r '.urls[]' | grep '^https://')
    if [[ -n "$NEW_DOMAIN" ]]; then
      echo "✅ Pinggy URL retrieved: $NEW_DOMAIN"
      break
    fi
  fi

  echo "❌ Failed to retrieve Pinggy URL. Retrying in $RETRY_DELAY seconds..."
  kill $PINGGY_PID
  rm -f "$TMP_FILE"
  sleep $RETRY_DELAY
  MAX_RETRIES=$((MAX_RETRIES - 1))
  if [[ $MAX_RETRIES -le 0 ]]; then
    echo "❌ Max retries reached. Exiting."
    exit 1
  fi
done

# Clean domain and resolve IP
NEW_DOMAIN_CLEAN=$(echo "$NEW_DOMAIN" | sed -E 's|https?://||')
DOMAIN_IP=$(host "$NEW_DOMAIN_CLEAN" | awk '/has address/ { print $4; exit }')

# Update .env
TMP_ENV=$(mktemp)
awk -v url="$NEW_DOMAIN" -v host="$NEW_DOMAIN_CLEAN" '
BEGIN {
  found_url=0; found_host=0;
}
{
  if ($0 ~ /^N8N_URL=/) {
    print "N8N_URL=" url;
    found_url=1;
  } else if ($0 ~ /^N8N_HOST=/) {
    print "N8N_HOST=" host;
    found_host=1;
  } else {
    print $0;
  }
}
END {
  if (!found_url) print "N8N_URL=" url;
  if (!found_host) print "N8N_HOST=" host;
}
' "$TARGET_FILE" > "$TMP_ENV" && cat "$TMP_ENV" > "$TARGET_FILE" && rm "$TMP_ENV"

echo "🔧 Updated $TARGET_FILE with Pinggy tunnel:"
grep -E '^N8N_(URL|HOST)=' "$TARGET_FILE"

echo "Pinggy tunnel running with PID $PINGGY_PID"
echo "To stop it: kill $PINGGY_PID"

# Export updated vars
export $(grep -v '^#' "$TARGET_FILE" | xargs)

