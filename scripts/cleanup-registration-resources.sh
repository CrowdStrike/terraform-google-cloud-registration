#!/bin/bash

# CrowdStrike GCP Registration cleanup script

set -e

# =============================================================================
# ARGUMENT PARSING AND VALIDATION
# =============================================================================

TFVARS_FILE=""
REGISTRATION_ID=""
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tfvars-file)
            TFVARS_FILE="$2"
            shift 2
            ;;
        --registration-id)
            REGISTRATION_ID="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 --tfvars-file <file> --registration-id <id> [--dry-run]"
            echo ""
            echo "Options:"
            echo "  --tfvars-file <file>       Path to terraform.tfvars file"
            echo "  --registration-id <id>     CrowdStrike registration ID"
            echo "  --dry-run                  Show what would be deleted without actually deleting"
            echo "  -h, --help                 Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$TFVARS_FILE" || -z "$REGISTRATION_ID" ]]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 --tfvars-file <file> --registration-id <id> [--dry-run]"
    echo "Use --help for more information"
    exit 1
fi

if [[ ! -f "$TFVARS_FILE" ]]; then
    echo "Error: File not found: $TFVARS_FILE"
    exit 1
fi

# Check gcloud authentication
active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
if [[ -z "$active_account" ]]; then
    echo "Error: No active gcloud authentication found. Please run 'gcloud auth login'"
    exit 1
fi

# =============================================================================
# INITIALIZATION AND DISCOVERY
# =============================================================================

initialize_cleanup_context() {
    echo "=== Parsing Configuration and Discovering Resources ==="

    # Parse variables from tfvars (excluding comments)
    WIF_PROJECT_ID=$(grep '^wif_project_id' "$TFVARS_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "")
    INFRA_PROJECT_ID=$(grep '^infra_project_id' "$TFVARS_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/')
    RESOURCE_PREFIX=$(grep '^resource_prefix' "$TFVARS_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "")
    RESOURCE_SUFFIX=$(grep '^resource_suffix' "$TFVARS_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "")
    REGISTRATION_TYPE=$(grep '^registration_type' "$TFVARS_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "")
    ORGANIZATION_ID=$(grep '^organization_id' "$TFVARS_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "")
    FOLDER_IDS=$(grep '^folder_ids' "$TFVARS_FILE" | sed 's/.*= *\[\([^]]*\)\].*/\1/' | tr -d '"' | tr ',' ' ' || echo "")
    PROJECT_IDS=$(grep '^project_ids' "$TFVARS_FILE" | sed 's/.*= *\[\([^]]*\)\].*/\1/' | tr -d '"' | tr ',' ' ' || echo "")

    # Default WIF project to infra project if not set
    if [[ -z "$WIF_PROJECT_ID" ]]; then
        WIF_PROJECT_ID="$INFRA_PROJECT_ID"
    fi

    echo "WIF Project: $WIF_PROJECT_ID"
    echo "Registration Type: $REGISTRATION_TYPE"
    echo "Resource prefix: '$RESOURCE_PREFIX'"
    echo "Resource suffix: '$RESOURCE_SUFFIX'"
    if [[ -n "$ORGANIZATION_ID" ]]; then
        echo "Organization ID: $ORGANIZATION_ID"
    fi
    if [[ -n "$FOLDER_IDS" ]]; then
        echo "Folder IDs: $FOLDER_IDS"
    fi
    if [[ -n "$PROJECT_IDS" ]]; then
        echo "Project IDs: $PROJECT_IDS"
    fi

    # Build display name patterns from terraform module
    POOL_DISPLAY_NAME="${RESOURCE_PREFIX}CrowdStrikeIDPool${RESOURCE_SUFFIX}"
    PROVIDER_DISPLAY_NAME="${RESOURCE_PREFIX}CrowdStrikeProvider${RESOURCE_SUFFIX}"

    # Find WIF pools by searching for the registration ID in IAM principals
    project_number=$(gcloud projects describe "$WIF_PROJECT_ID" --format="value(projectNumber)" 2>/dev/null)

    if [[ -z "$project_number" ]]; then
        echo "Error: Could not get project number for $WIF_PROJECT_ID"
        exit 1
    fi

    # Get IAM policy and search for the specific registration ID
    policy=$(gcloud projects get-iam-policy "$INFRA_PROJECT_ID" --format=json 2>/dev/null || echo '{"bindings":[]}')

    # Use jq to filter and then grep to find the registration ID
    principal_with_reg_id=$(echo "$policy" | jq -r '.bindings[]?.members[]?' 2>/dev/null | grep "$REGISTRATION_ID" | head -n1)

    if [[ -z "$principal_with_reg_id" ]]; then
        echo "No WIF principal found for registration ID: $REGISTRATION_ID"
        exit 0
    fi

    # Extract pool ID from the principal
    pool_id=$(echo "$principal_with_reg_id" | sed 's/.*workloadIdentityPools\/\([^/]*\).*/\1/')
    WIF_POOLS="projects/$project_number/locations/global/workloadIdentityPools/$pool_id"
}

# =============================================================================
# CLEANUP FUNCTIONS
# =============================================================================

cleanup_log_ingestion() {
    echo "=== Starting Log Ingestion Cleanup ==="

    registration_id="$1"
    topic_name=""
    subscription_name=""
    sink_name=""
    schema_name=""

    topic_name="${RESOURCE_PREFIX}CrowdStrikeLogTopic-${registration_id}${RESOURCE_SUFFIX}"
    subscription_name="${RESOURCE_PREFIX}CrowdStrikeLogSubscription-${registration_id}${RESOURCE_SUFFIX}"
    sink_name="${RESOURCE_PREFIX}CrowdStrikeLogSink${RESOURCE_SUFFIX}"
    schema_name="${RESOURCE_PREFIX}CrowdStrikeLogSchema${RESOURCE_SUFFIX}"

    # Clean up log sinks
    case "$REGISTRATION_TYPE" in
    "organization")
        if [[ -n "$ORGANIZATION_ID" ]]; then
            if gcloud logging sinks describe "$sink_name" --organization="$ORGANIZATION_ID" >/dev/null 2>&1; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] Would delete organization log sink: $sink_name"
                else
                    echo "Deleting organization log sink: $sink_name"
                    gcloud logging sinks delete "$sink_name" --organization="$ORGANIZATION_ID" --quiet
                fi
            else
                echo "Organization log sink not found: $sink_name"
            fi
        fi
        ;;
    "folder")
        for folder_id in $FOLDER_IDS; do
            sink_name_with_folder="${sink_name}-${folder_id}"
            if gcloud logging sinks describe "$sink_name_with_folder" --folder="$folder_id" >/dev/null 2>&1; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] Would delete folder log sink: $sink_name_with_folder"
                else
                    echo "Deleting folder log sink: $sink_name_with_folder"
                    gcloud logging sinks delete "$sink_name_with_folder" --folder="$folder_id" --quiet
                fi
            else
                echo "Folder log sink not found: $sink_name_with_folder"
            fi
        done
        ;;
    "project")
        for project_id in $PROJECT_IDS; do
            sink_name_with_project="${sink_name}-${project_id}"
            if gcloud logging sinks describe "$sink_name_with_project" --project="$project_id" >/dev/null 2>&1; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] Would delete project log sink: $sink_name_with_project"
                else
                    echo "Deleting project log sink: $sink_name_with_project"
                    gcloud logging sinks delete "$sink_name_with_project" --project="$project_id" --quiet
                fi
            else
                echo "Project log sink not found: $sink_name_with_project"
            fi
        done
        ;;
    esac

    # Clean up Pub/Sub subscription
    if gcloud pubsub subscriptions describe "$subscription_name" --project="$INFRA_PROJECT_ID" >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would delete Pub/Sub subscription: $subscription_name"
        else
            echo "Deleting Pub/Sub subscription: $subscription_name"
            gcloud pubsub subscriptions delete "$subscription_name" --project="$INFRA_PROJECT_ID" --quiet
        fi
    else
        echo "Pub/Sub subscription not found: $subscription_name"
    fi

    # Clean up Pub/Sub topic
    if gcloud pubsub topics describe "$topic_name" --project="$INFRA_PROJECT_ID" >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would delete Pub/Sub topic: $topic_name"
        else
            echo "Deleting Pub/Sub topic: $topic_name"
            gcloud pubsub topics delete "$topic_name" --project="$INFRA_PROJECT_ID" --quiet
        fi
    else
        echo "Pub/Sub topic not found: $topic_name"
    fi

    # Clean up Pub/Sub schema
    if gcloud pubsub schemas describe "$schema_name" --project="$INFRA_PROJECT_ID" >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would delete Pub/Sub schema: $schema_name"
        else
            echo "Deleting Pub/Sub schema: $schema_name"
            gcloud pubsub schemas delete "$schema_name" --project="$INFRA_PROJECT_ID" --quiet
        fi
    else
        echo "Pub/Sub schema not found: $schema_name"
    fi
}

cleanup_asset_inventory() {
    echo "=== Starting Asset Inventory IAM Cleanup ==="

    # Find the WIF principal by discovering it from the pool
    if [[ -z "$WIF_POOLS" ]]; then
        echo "No WIF pools found - skipping IAM cleanup"
        return
    fi

    pool_name=$(echo "$WIF_POOLS" | head -n1)
    pool_id=$(basename "$pool_name")

    # Get project number for principal construction
    project_number=$(gcloud projects describe "$WIF_PROJECT_ID" --format="value(projectNumber)" 2>/dev/null)

    if [[ -z "$project_number" ]]; then
        echo "Could not get project number for $WIF_PROJECT_ID"
        return
    fi

    # Construct the principal pattern to search for
    principal_pattern="principal://iam.googleapis.com/projects/$project_number/locations/global/workloadIdentityPools/$pool_id"

    # Function to clean IAM bindings for discovered principals
    cleanup_discovered_iam_bindings() {
        scope_type="$1"
        scope_id="$2"
        cmd_prefix=""

        case $scope_type in
            "organization")
                cmd_prefix="gcloud organizations"
                ;;
            "folder")
                cmd_prefix="gcloud resource-manager folders"
                ;;
            "project")
                cmd_prefix="gcloud projects"
                ;;
        esac

        echo "Cleaning IAM bindings for $scope_type: $scope_id"

        # Get all IAM policy bindings and find CrowdStrike principals
        policy=$($cmd_prefix get-iam-policy "$scope_id" --format=json 2>/dev/null || echo '{"bindings":[]}')

        # Find all members that match our specific registration ID
        crowdstrike_bindings=$(echo "$policy" | jq -r --arg reg_id "$REGISTRATION_ID" '.bindings[] | select(.members[]? | contains($reg_id)) | .role as $role | .members[] | select(contains($reg_id)) | "\($role)||||\(.)"' 2>/dev/null || true)

        while read -r binding; do
            if [[ -n "$binding" ]]; then
                role=$(echo "$binding" | cut -d'|' -f1)
                member=$(echo "$binding" | cut -d'|' -f5-)
                if [[ -n "$role" && -n "$member" ]]; then
                    if [[ "$DRY_RUN" == "true" ]]; then
                        echo "[DRY RUN] Would remove IAM binding: $role from $member"
                    else
                        echo "Removing IAM binding: $role from $member"
                        if ! $cmd_prefix remove-iam-policy-binding "$scope_id" --member="$member" --role="$role" --quiet 2>/dev/null; then
                            echo "Failed to remove IAM binding: $role from $member"
                        fi
                    fi
                fi
            fi
        done <<< "$crowdstrike_bindings"
    }

    # Cleanup based on registration type
    if [[ "$REGISTRATION_TYPE" == "organization" && -n "$ORGANIZATION_ID" ]]; then
        cleanup_discovered_iam_bindings "organization" "$ORGANIZATION_ID"
    elif [[ "$REGISTRATION_TYPE" == "folder" && -n "$FOLDER_IDS" ]]; then
        for folder_id in $FOLDER_IDS; do
            cleanup_discovered_iam_bindings "folder" "$folder_id"
        done
    elif [[ "$REGISTRATION_TYPE" == "project" && -n "$PROJECT_IDS" ]]; then
        for project_id in $PROJECT_IDS; do
            cleanup_discovered_iam_bindings "project" "$project_id"
        done
    else
        echo "No valid registration scope found for asset inventory cleanup"
    fi
}

cleanup_wif_resources() {
    echo "=== Starting WIF Cleanup ==="

    if [[ -z "$WIF_POOLS" ]]; then
        echo "No WIF pools found - skipping WIF cleanup"
        return
    fi

    # Find WIF providers using display name
    for pool_name in $WIF_POOLS; do
        pool_id=$(basename "$pool_name")
        providers=$(gcloud iam workload-identity-pools providers list --workload-identity-pool="$pool_id" --project="$WIF_PROJECT_ID" --location=global --format="value(name)" --filter="displayName='$PROVIDER_DISPLAY_NAME'" 2>/dev/null || true)
        if [[ -n "$providers" ]]; then
            # Delete providers
            for provider_name in $providers; do
                provider_id=$(basename "$provider_name")
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] Would delete provider: $provider_id (display: $PROVIDER_DISPLAY_NAME)"
                else
                    echo "Deleting provider: $provider_id (display: $PROVIDER_DISPLAY_NAME)"
                    gcloud iam workload-identity-pools providers delete "$provider_id" --workload-identity-pool="$pool_id" --project="$WIF_PROJECT_ID" --location=global --quiet
                fi
            done
        fi
    done

    # Delete pools
    for pool_name in $WIF_POOLS; do
        pool_id=$(basename "$pool_name")
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would delete pool: $pool_id (display: $POOL_DISPLAY_NAME)"
        else
            echo "Deleting pool: $pool_id (display: $POOL_DISPLAY_NAME)"
            gcloud iam workload-identity-pools delete "$pool_id" --project="$WIF_PROJECT_ID" --location=global --quiet
        fi
    done
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

echo "=== Starting Resource Cleanup ==="
echo
initialize_cleanup_context
echo
cleanup_log_ingestion "$REGISTRATION_ID"
echo
cleanup_asset_inventory
echo
cleanup_wif_resources
echo
echo "=== Cleanup Complete ==="
