#!/bin/bash

# Configuration
KEYCLOAK_URL="https://keycloak:8443"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin"
REALM_NAME="test-realm"
REALM_DISPLAY_NAME="My Realm"
REALM_FILE="realm.json"
# sleep 10
echo "wanda time"
# Create realm JSON payload
cat > "$REALM_FILE" <<EOF
{
  "realm": "$REALM_NAME",
  "displayName": "$REALM_DISPLAY_NAME",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": false,
  "loginWithEmailAllowed": true,
  "duplicateEmailsAllowed": false,
  "resetPasswordAllowed": false,
  "editUsernameAllowed": false,
  "bruteForceProtected": true
}
EOF

# Obtain access token
ACCESS_TOKEN=$(curl -k -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  -d "username=$ADMIN_USERNAME" \
  -d "password=$ADMIN_PASSWORD" | jq -r '.access_token')
echo "$ACCESS_TOKEN"
# Check if access token was obtained
if [ -z "$ACCESS_TOKEN" ]; then
  echo "Failed to obtain access token."
  exit 1
fi

# Check if realm already exists
EXISTING_REALM=$(curl -k -s -o /dev/null -w "%{http_code}" -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$EXISTING_REALM" -eq 200 ]; then
  echo "Realm '$REALM_NAME' already exists. Skipping creation."
else
  # Create the new realm
  RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" -X POST "$KEYCLOAK_URL/admin/realms" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d @"$REALM_FILE")

  if [ "$RESPONSE" -eq 201 ]; then
    echo "Realm '$REALM_NAME' created successfully."
  else
    echo "Failed to create realm. HTTP status code: $RESPONSE"
    exit 1
  fi
fi

# Check if role exists
EXISTING_ROLE=$(curl -k -s -o /dev/null -w "%{http_code}" -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles/success" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$EXISTING_ROLE" -eq 200 ]; then
  echo "Role 'success' already exists. Skipping creation."
else
  ROLE_PAYLOAD='{ "name": "success" }'
  RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$ROLE_PAYLOAD")

  if [ "$RESPONSE" -eq 201 ]; then
    echo "Role 'success' created successfully."
  else
    echo "Failed to create role. HTTP status code: $RESPONSE"
  fi
fi

# Check if user exists
USER_ID=$(curl -k -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users?username=user" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.[0].id')

if [ "$USER_ID" != "null" ] && [ -n "$USER_ID" ]; then
  echo "User 'user' already exists. Skipping creation."
else
  USER_PAYLOAD='{
    "username": "user",
    "enabled": true,
    "credentials": [
      {
        "type": "password",
        "value": "user",
        "temporary": false
      }
    ]
  }'
  RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$USER_PAYLOAD")

  if [ "$RESPONSE" -eq 201 ]; then
    echo "User 'user' created successfully."
  else
    echo "Failed to create user. HTTP status code: $RESPONSE"
  fi
fi

# Check if client exists
EXISTING_CLIENT=$(curl -k -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients?clientId=test-app" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.[0].id')

if [ "$EXISTING_CLIENT" != "null" ] && [ -n "$EXISTING_CLIENT" ]; then
  echo "Client 'test-app' already exists. Skipping creation."
else
  CLIENT_PAYLOAD='{
    "clientId": "test-app",
    "enabled": true,
    "publicClient": true,
    "redirectUris": ["https://app.ctt.tn/*"],
    "webOrigins": ["https://app.ctt.tn"]
  }'
  RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$CLIENT_PAYLOAD")

  if [ "$RESPONSE" -eq 201 ]; then
    echo "Client 'test-app' created successfully."
  else
    echo "Failed to create client. HTTP status code: $RESPONSE"
  fi
fi

# Clean up
rm -f "$REALM_FILE"

