#!/bin/bash
set -e

# CrowdStrike Registration Settings Update Script - Internal/Dodo Environment
echo "=== CrowdStrike Registration Completion - Internal ==="

# Validate required environment variables
REQUIRED_VARS=("CUSTOMER_ID" "REGISTRATION_ID" "WIF_POOL_ID" "WIF_PROJECT_NUMBER")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "ERROR: Required environment variable $var is not set"
    exit 1
  fi
done

# Validate FALCON_CLOUD_API_HOST is provided
if [ -z "$FALCON_CLOUD_API_HOST" ]; then
  echo "ERROR: FALCON_CLOUD_API_HOST environment variable is required"
  exit 1
fi

# Complete registration
echo "1. Completing registration..."

COMPLETION_RESPONSE=$(curl -s -w "\\n%{http_code}" -X PATCH "${FALCON_CLOUD_API_HOST}/cloud-security-registration-google-cloud/entities/registrations/v1?ids=${REGISTRATION_ID}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "X-CS-CUSTID: $CUSTOMER_ID" \
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

echo "2. Results:"
echo "   ✓ Registration completed successfully!"
echo "   Project Number: $WIF_PROJECT_NUMBER"