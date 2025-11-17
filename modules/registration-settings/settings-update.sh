#!/bin/bash
set -e

# CrowdStrike Registration Settings Update Script - Public API
echo "=== CrowdStrike Registration Completion - Public API ==="

# Validate required environment variables
REQUIRED_VARS=("FALCON_CLIENT_ID" "FALCON_CLIENT_SECRET" "FALCON_API_HOST" "FALCON_CLOUD_API_HOST" "REGISTRATION_ID" "WIF_PROJECT_NUMBER")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "ERROR: Required environment variable $var is not set"
    exit 1
  fi
done

# Get OAuth token
echo "1. Obtaining OAuth token..."
TOKEN_RESPONSE=$(curl -s -w "\\n%{http_code}" -X POST "${FALCON_API_HOST}/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=${FALCON_CLIENT_ID}&client_secret=${FALCON_CLIENT_SECRET}&grant_type=client_credentials")

HTTP_CODE=$(echo "$TOKEN_RESPONSE" | tail -n1)
TOKEN_BODY=$(echo "$TOKEN_RESPONSE" | sed '$d')

echo "   HTTP Code: $HTTP_CODE"

if [ "$HTTP_CODE" -ne 200 ] && [ "$HTTP_CODE" -ne 201 ]; then
  echo "ERROR: OAuth token request failed"
  echo "Response: $TOKEN_BODY"
  exit 1
fi

ACCESS_TOKEN=$(echo "$TOKEN_BODY" | jq -r '.access_token')
if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "ERROR: Failed to extract access token"
  echo "Response: $TOKEN_BODY"
  exit 1
fi

echo "   ✓ OAuth token obtained"

# Complete registration
echo "2. Completing registration..."

COMPLETION_RESPONSE=$(curl -s -w "\\n%{http_code}" -X PATCH "${FALCON_CLOUD_API_HOST}/cloud-security-registration-google-cloud/entities/registrations/v1?ids=${REGISTRATION_ID}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "resources": [{
      "log_ingestion_sink_name": "'"$LOG_SINK_NAME"'",
      "log_ingestion_subscription_name": "'"$LOG_SUBSCRIPTION_ID"'",
      "log_ingestion_topic_id": "'"$LOG_TOPIC_ID"'",
      "wif_project_id": "'"$WIF_PROJECT_ID"'",
      "wif_project_number": "'"$WIF_PROJECT_NUMBER"'"
    }]
  }')

COMPLETION_HTTP_CODE=$(echo "$COMPLETION_RESPONSE" | tail -n1)
COMPLETION_BODY=$(echo "$COMPLETION_RESPONSE" | sed '$d')

echo "   HTTP Code: $COMPLETION_HTTP_CODE"

if [[ ! "$COMPLETION_HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
  echo "ERROR: Registration completion failed"
  echo "Response: $COMPLETION_BODY"
  exit 1
fi

echo "3. Results:"
echo "   ✓ Registration completed successfully!"
echo "   Project Number: $WIF_PROJECT_NUMBER"