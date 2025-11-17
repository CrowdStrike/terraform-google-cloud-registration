#!/bin/bash
set -e

# CrowdStrike GCP Registration Script - Internal/Dodo Environment
OPERATION=${OPERATION:-"CREATE"}
echo "=== CrowdStrike GCP Registration - Internal ($OPERATION) ==="

# Validate required environment variables
case "$OPERATION" in
  "CREATE")
    REQUIRED_VARS=("FALCON_CLIENT_ID" "FALCON_CLIENT_SECRET" "CUSTOMER_ID" "REGISTRATION_NAME" "REGISTRATION_SCOPE" "INFRA_PROJECT_ID" "WIF_PROJECT_ID")
    ;;
  "DELETE")
    REQUIRED_VARS=("FALCON_CLIENT_ID" "FALCON_CLIENT_SECRET" "CUSTOMER_ID" "REGISTRATION_ID")
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

# Validate FALCON_CLOUD_API_HOST is provided
if [ -z "$FALCON_CLOUD_API_HOST" ]; then
  echo "ERROR: FALCON_CLOUD_API_HOST environment variable is required"
  exit 1
fi

# Function to create registration
create_registration() {
  echo "1. Creating GCP registration..."
  
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
    -H "X-CS-CUSTID: $CUSTOMER_ID" \
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

  if [[ ! "$REG_HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
    echo "ERROR: Registration API call failed"
    echo "Response: $REG_BODY"
    exit 1
  fi

  # Extract registration details
  REGISTRATION_ID=$(echo "$REG_BODY" | jq -r '.resources[0].registration_id // .resources[0].id // empty')
  WIF_POOL_ID=$(echo "$REG_BODY" | jq -r '.resources[0].wif_properties.pool_id // empty')
  WIF_PROVIDER_ID=$(echo "$REG_BODY" | jq -r '.resources[0].wif_properties.provider_id // empty')

  # Write extracted values to files for Terraform to read
  if [ -n "$RANDOM_SUFFIX" ]; then
    echo "$REGISTRATION_ID" > /tmp/cs_registration_id_${RANDOM_SUFFIX}.txt
    echo "$WIF_POOL_ID" > /tmp/cs_wif_pool_id_${RANDOM_SUFFIX}.txt
    echo "$WIF_PROVIDER_ID" > /tmp/cs_wif_provider_id_${RANDOM_SUFFIX}.txt
  fi

  echo "2. Results:"
  echo "   Registration ID: $REGISTRATION_ID"
  echo "   WIF Pool ID: $WIF_POOL_ID" 
  echo "   WIF Provider ID: $WIF_PROVIDER_ID"
  echo "   ✓ Registration created successfully!"
}

# Function to delete registration
delete_registration() {
  echo "1. Deleting GCP registration..."
  
  if [ -z "$REGISTRATION_ID" ]; then
    echo "   ERROR: Registration ID is empty"
    exit 1
  fi
  
  if [ -z "$CUSTOMER_ID" ]; then
    echo "   ERROR: Customer ID is empty"
    exit 1
  fi
  
  CLEAN_URL=$(echo "${FALCON_CLOUD_API_HOST}/cloud-security-registration-google-cloud/entities/registrations/v1?ids=${REGISTRATION_ID}" | tr -d '\r\n\t' | sed 's/[[:space:]]*$//')
  DELETE_RESPONSE=$(curl -s -w "\\n%{http_code}" -X DELETE "$CLEAN_URL" -H "accept: application/json" -H "X-CS-CUSTID: $CUSTOMER_ID")
  
  HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)
  echo "   HTTP Code: $HTTP_CODE"

  if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
    echo "2. Results:"
    echo "   ✓ Successfully deleted GCP registration"
  else
    echo "2. Results:"
    echo "   ❌ Delete request failed with code $HTTP_CODE"
    echo "   Response: $(echo "$DELETE_RESPONSE" | sed '$d')"
    exit 1
  fi
}

# Main execution
case "$OPERATION" in
  "CREATE")
    create_registration
    ;;
  "DELETE")
    delete_registration
    ;;
esac

echo "GCP registration $OPERATION completed"