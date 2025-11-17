#!/bin/bash
set -e

# CrowdStrike GCP Registration Script - Public API
# Handles CREATE and DELETE operations using Bearer token authentication

OPERATION=${OPERATION:-"CREATE"}

echo "=== CrowdStrike GCP Registration - Public API ($OPERATION) ==="

# Validate required environment variables
case "$OPERATION" in
  "CREATE")
    REQUIRED_VARS=("FALCON_CLIENT_ID" "FALCON_CLIENT_SECRET" "REGISTRATION_NAME" "REGISTRATION_SCOPE" "INFRA_PROJECT_ID" "WIF_PROJECT_ID")
    ;;
  "DELETE")
    REQUIRED_VARS=("FALCON_CLIENT_ID" "FALCON_CLIENT_SECRET" "REGISTRATION_ID")
    ;;
  *)
    echo "ERROR: Invalid OPERATION. Must be CREATE or DELETE"
    exit 1
    ;;
esac

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "ERROR: Required environment variable $var is not set"
    exit 1
  fi
done

# Validate required API hosts
if [ -z "$FALCON_API_HOST" ]; then
  echo "ERROR: FALCON_API_HOST environment variable is required for OAuth"
  exit 1
fi

if [ -z "$FALCON_CLOUD_API_HOST" ]; then
  echo "ERROR: FALCON_CLOUD_API_HOST environment variable is required for registration"
  exit 1
fi

# Function to get OAuth token
get_oauth_token() {
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
}

# Function to create registration
create_registration() {
  echo "2. Creating GCP registration..."
  
  # Build features array based on enable_realtime_visibility
  if [ "${ENABLE_REALTIME_VISIBILITY}" = "true" ]; then
    FEATURES_JSON='"iom", "ioa"'
  else
    FEATURES_JSON='"iom"'
  fi
  
  # Build entity_id array based on registration scope
  case "$REGISTRATION_SCOPE" in
    "organization")
      ENTITY_IDS='"'$ORGANIZATION_ID'"'
      ;;
    "folder")
      # Convert comma-separated folder IDs to JSON array format
      ENTITY_IDS=$(echo "$FOLDER_IDS" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')
      ;;
    "project")
      # Convert comma-separated project IDs to JSON array format  
      ENTITY_IDS=$(echo "$PROJECT_IDS" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')
      ;;
    *)
      echo "ERROR: Invalid registration scope: $REGISTRATION_SCOPE"
      exit 1
      ;;
  esac
  
  REGISTRATION_RESPONSE=$(curl -s -w "\\n%{http_code}" -X PUT "${FALCON_CLOUD_API_HOST}/cloud-security-registration-google-cloud/entities/registrations/v1" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d '{
      "resources": [{
        "registration_name": "'"$REGISTRATION_NAME"'",
        "registration_scope": "'"$REGISTRATION_SCOPE"'",
        "deployment_method": "terraform-native",
        "entity_id": ['"$ENTITY_IDS"'],
        "products": [
          {
            "product": "cspm",
            "features": [
              '"$FEATURES_JSON"'
            ]
          }
        ],
        "infra_project_id": "'"$INFRA_PROJECT_ID"'",
        "wif_project_id": "'"$WIF_PROJECT_ID"'",
        "resource_name_prefix": "'"$RESOURCE_PREFIX"'",
        "resource_name_suffix": "'"$RESOURCE_SUFFIX"'"
      }]
    }')

  REG_HTTP_CODE=$(echo "$REGISTRATION_RESPONSE" | tail -n1)
  REG_BODY=$(echo "$REGISTRATION_RESPONSE" | sed '$d')

  echo "   HTTP Code: $REG_HTTP_CODE"

  if [ "$REG_HTTP_CODE" -ne 200 ] && [ "$REG_HTTP_CODE" -ne 201 ]; then
    echo "ERROR: Registration API call failed"
    echo "Response: $REG_BODY"
    exit 1
  fi

  # Extract registration details
  REGISTRATION_ID=$(echo "$REG_BODY" | jq -r '.resources[0].registration_id // .resources[0].id // empty' 2>/dev/null || echo "")
  WIF_POOL_ID=$(echo "$REG_BODY" | jq -r '.resources[0].wif_properties.pool_id // empty' 2>/dev/null || echo "")
  WIF_PROVIDER_ID=$(echo "$REG_BODY" | jq -r '.resources[0].wif_properties.provider_id // empty' 2>/dev/null || echo "")

  # Write extracted values to files for Terraform to read
  echo "$REGISTRATION_ID" > /tmp/cs_registration_id_${RANDOM_SUFFIX}.txt
  echo "$WIF_POOL_ID" > /tmp/cs_wif_pool_id_${RANDOM_SUFFIX}.txt
  echo "$WIF_PROVIDER_ID" > /tmp/cs_wif_provider_id_${RANDOM_SUFFIX}.txt

  echo "3. Results:"
  echo "   Registration ID: $REGISTRATION_ID"
  echo "   WIF Pool ID: $WIF_POOL_ID" 
  echo "   WIF Provider ID: $WIF_PROVIDER_ID"

  if [ -n "$REGISTRATION_ID" ]; then
    echo "   ✓ Registration created successfully!"
  else
    echo "   ERROR: Could not extract registration_id"
    exit 1
  fi
}

# Function to delete registration
delete_registration() {
  echo "2. Deleting GCP registration..."
  
  if [ -z "$REGISTRATION_ID" ]; then
    echo "   ERROR: Registration ID is empty"
    exit 1
  fi
  
  DELETE_URL=$(echo "${FALCON_CLOUD_API_HOST}/cloud-security-registration-google-cloud/entities/registrations/v1?ids=${REGISTRATION_ID}" | tr -d '\r\n\t' | sed 's/[[:space:]]*$//')
  
  DELETE_RESPONSE=$(curl --connect-timeout 10 --max-time 30 -s -w "\n%{http_code}" -X DELETE "$DELETE_URL" \
    -H "accept: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" 2>&1)
  
  CURL_EXIT_CODE=$?
  
  if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "   ERROR: Curl command failed with exit code $CURL_EXIT_CODE"
    echo "   Response: $DELETE_RESPONSE"
    exit 1
  fi

  # Extract HTTP code - handle both "200" and "200%" formats
  HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1 | tr -d '%')
  DELETE_BODY=$(echo "$DELETE_RESPONSE" | sed '$d')

  echo "   HTTP Code: $HTTP_CODE"

  if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
    echo "3. Results:"
    echo "   ✓ Successfully deleted GCP registration"
  else
    echo "3. Results:"
    echo "   ❌ Delete request failed with code $HTTP_CODE"
    echo "   Full Response: $DELETE_BODY"
    exit 1
  fi
}

# Main execution
get_oauth_token

case "$OPERATION" in
  "CREATE")
    create_registration
    ;;
  "DELETE")
    delete_registration
    ;;
esac

echo "GCP registration $OPERATION completed"