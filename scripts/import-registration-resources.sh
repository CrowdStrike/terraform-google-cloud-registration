#!/bin/bash

# CrowdStrike GCP Registration import script
#
# This script helps recover orphaned GCP resources back into Terraform state
# by generating terraform import commands for CrowdStrike CSPM registrations.

set -e

# =============================================================================
# ARGUMENT PARSING AND VALIDATION
# =============================================================================

TERRAFORM_DIR=""
REGISTRATION_ID=""
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --terraform-dir)
            TERRAFORM_DIR="$2"
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
            echo "CrowdStrike GCP Registration Import Script"
            echo ""
            echo "This script discovers orphaned GCP resources from a CrowdStrike CSPM"
            echo "registration and generates terraform import commands to bring them"
            echo "back into Terraform state."
            echo ""
            echo "Usage: $0 --terraform-dir <dir> --registration-id <id> [OPTIONS]"
            echo ""
            echo "Required Options:"
            echo "  --terraform-dir <dir>      Directory containing Terraform config and terraform.tfvars"
            echo "  --registration-id <id>     CrowdStrike registration ID"
            echo ""
            echo "Optional:"
            echo "  --dry-run                  Show import commands without executing them"
            echo "  -h, --help                 Show this help message"
            echo ""
            echo "Note: GCP API enablement resources are not imported and will appear as new"
            echo "resources in terraform plan. This is expected and safe to apply."
            echo ""
            echo "Examples:"
            echo "  $0 --terraform-dir ./terraform --registration-id abc123 --dry-run"
            echo "  $0 --terraform-dir ./examples/native-terraform --registration-id abc123"
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
if [[ -z "$TERRAFORM_DIR" || -z "$REGISTRATION_ID" ]]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 --terraform-dir <dir> --registration-id <id> [OPTIONS]"
    echo "Use --help for more information"
    exit 1
fi

TFVARS_FILE="$TERRAFORM_DIR/terraform.tfvars"

if [[ ! -f "$TFVARS_FILE" ]]; then
    echo "Error: terraform.tfvars not found in: $TERRAFORM_DIR"
    echo "Expected file: $TFVARS_FILE"
    exit 1
fi

# Check gcloud authentication
active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
if [[ -z "$active_account" ]]; then
    echo "Error: No active gcloud authentication found. Please run 'gcloud auth login'"
    exit 1
fi

# Check terraform availability
if ! type terraform >/dev/null 2>&1; then
    echo "Error: terraform command not found. Please install Terraform"
    exit 1
fi

# Validate terraform directory
if [[ ! -d "$TERRAFORM_DIR" ]]; then
    echo "Error: Terraform directory not found: $TERRAFORM_DIR"
    exit 1
fi

# Check if terraform has been initialized
if [[ ! -d "$TERRAFORM_DIR/.terraform" ]]; then
    echo "Error: Terraform not initialized in: $TERRAFORM_DIR"
    echo "Please run 'terraform init' in the terraform directory first"
    exit 1
fi

# =============================================================================
# INITIALIZATION AND DISCOVERY
# =============================================================================

initialize_import_context() {
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

    policy=$(gcloud projects get-iam-policy "$INFRA_PROJECT_ID" --format=json 2>/dev/null)
    if [[ $? -ne 0 || -z "$policy" ]]; then
        echo "Error: Failed to get IAM policy for project '$INFRA_PROJECT_ID'"
        echo "Please check authentication: gcloud auth login"
        exit 1
    fi

    principal_with_reg_id=$(echo "$policy" | jq -r '.bindings[]?.members[]?' 2>/dev/null | grep "$REGISTRATION_ID" | head -n1)

    if [[ -z "$principal_with_reg_id" ]]; then
        echo "WARNING: No WIF principal found for registration ID: $REGISTRATION_ID"
        WIF_POOLS=""
    else
        # Extract pool ID from the principal
        pool_id=$(echo "$principal_with_reg_id" | sed 's/.*workloadIdentityPools\/\([^/]*\).*/\1/')
        WIF_POOLS="projects/$WIF_PROJECT_ID/locations/global/workloadIdentityPools/$pool_id"
    fi
}

# =============================================================================
# IMPORT FUNCTIONS
# =============================================================================

import_crowdstrike_resources() {
    echo "=== Importing CrowdStrike Provider Resources ==="

    # Import CrowdStrike registration
    local registration_resource="module.crowdstrike_gcp_registration.crowdstrike_cloud_google_registration.main"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would execute: terraform import \"$registration_resource\" \"$REGISTRATION_ID\""
    else
        cd "$TERRAFORM_DIR"
        if terraform import "$registration_resource" "$REGISTRATION_ID" >/dev/null 2>&1; then
            echo "Successfully imported CrowdStrike registration"
        else
            echo "Failed to import CrowdStrike registration"
            terraform import "$registration_resource" "$REGISTRATION_ID" || true
        fi
        cd - > /dev/null
    fi

    # Import CrowdStrike registration settings (if they exist)
    local settings_resource="module.crowdstrike_gcp_registration.crowdstrike_cloud_google_registration_settings.main"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would execute: terraform import \"$settings_resource\" \"$REGISTRATION_ID\""
    else
        cd "$TERRAFORM_DIR"
        if terraform import "$settings_resource" "$REGISTRATION_ID" >/dev/null 2>&1; then
            echo "Successfully imported CrowdStrike registration settings"
        else
            echo "Failed to import CrowdStrike registration settings"
            terraform import "$settings_resource" "$REGISTRATION_ID" || true
        fi
        cd - > /dev/null
    fi
}

import_wif_resources() {
    echo "=== Importing Workload Identity Federation Resources ==="

    if [[ -z "$WIF_POOLS" ]]; then
        echo "No WIF pools found - skipping WIF import"
        return
    fi

    # Import WIF pools and providers
    for pool_name in $WIF_POOLS; do
        pool_id=$(basename "$pool_name")

        # Import the WIF pool
        local pool_resource="module.crowdstrike_gcp_registration.module.workload-identity.google_iam_workload_identity_pool.main"
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would execute: terraform import \"$pool_resource\" \"$pool_name\""
        else
            cd "$TERRAFORM_DIR"
            if terraform import "$pool_resource" "$pool_name" >/dev/null 2>&1; then
                echo "Successfully imported WIF pool: $pool_id"
            else
                echo "Failed to import WIF pool: $pool_id"
                terraform import "$pool_resource" "$pool_name" || true
            fi
            cd - > /dev/null
        fi

        # Find and import WIF providers
        providers=$(gcloud iam workload-identity-pools providers list --workload-identity-pool="$pool_id" --project="$WIF_PROJECT_ID" --location=global --format="value(name)" --filter="displayName='$PROVIDER_DISPLAY_NAME'" 2>/dev/null || true)
        if [[ -n "$providers" ]]; then
            for provider_name in $providers; do
                provider_id=$(basename "$provider_name")
                provider_import_name="projects/$WIF_PROJECT_ID/locations/global/workloadIdentityPools/$pool_id/providers/$provider_id"

                local provider_resource="module.crowdstrike_gcp_registration.module.workload-identity.google_iam_workload_identity_pool_provider.aws"
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] terraform import \"$provider_resource\" \"$provider_import_name\""
                else
                    cd "$TERRAFORM_DIR"
                    if terraform import "$provider_resource" "$provider_import_name" >/dev/null 2>&1; then
                        echo "Successfully imported WIF provider: $provider_id"
                    else
                        echo "Failed to import WIF provider: $provider_id"
                        terraform import "$provider_resource" "$provider_import_name" || true
                    fi
                    cd - > /dev/null
                fi
            done
        fi
    done
}

import_asset_inventory_resources() {
    echo "=== Importing Asset Inventory IAM Resources ==="

    if [[ -z "$WIF_POOLS" ]]; then
        echo "No WIF pools found - skipping IAM import"
        return
    fi

    pool_name=$(echo "$WIF_POOLS" | head -n1)
    pool_id=$(basename "$pool_name")

    project_number=$(gcloud projects describe "$WIF_PROJECT_ID" --format="value(projectNumber)" 2>/dev/null)
    if [[ -z "$project_number" ]]; then
        echo "Error: Could not get project number for $WIF_PROJECT_ID"
        return
    fi

    # Function to import discovered IAM bindings
    import_discovered_iam_bindings() {
        scope_type="$1"
        scope_id="$2"
        cmd_prefix=""

        local log_ingestion_roles="roles/monitoring.viewer"

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

        echo "Importing IAM bindings for $scope_type: $scope_id"

        # Get all IAM policy bindings and find CrowdStrike principals
        policy=$($cmd_prefix get-iam-policy "$scope_id" --format=json 2>/dev/null || echo '{"bindings":[]}')

        # Find all members that match our specific registration ID
        crowdstrike_bindings=$(echo "$policy" | jq -r --arg reg_id "$REGISTRATION_ID" '.bindings[] | select(.members[]? | contains($reg_id)) | .role as $role | .members[] | select(contains($reg_id)) | "\($role)||||\(.)"' 2>/dev/null || true)

        while read -r binding; do
            if [[ -n "$binding" ]]; then
                role=$(echo "$binding" | cut -d'|' -f1)
                member=$(echo "$binding" | cut -d'|' -f5-)

                if [[ " $log_ingestion_roles " =~ " $role " ]]; then
                    echo "Skipping $role (managed by log-ingestion module)"
                    continue
                fi

                if [[ -n "$role" && -n "$member" ]]; then
                    # Construct terraform resource address and import ID based on scope type
                    case $scope_type in
                        "organization")
                            local resource_name="module.crowdstrike_gcp_registration.module.asset-inventory.google_organization_iam_member.crowdstrike_organization[\"$role\"]"
                            local import_id="$scope_id $role $member"
                            ;;
                        "folder")
                            local resource_key="${scope_id}::${role}"
                            local resource_name="module.crowdstrike_gcp_registration.module.asset-inventory.google_folder_iam_member.crowdstrike_folder[\"$resource_key\"]"
                            local import_id="folders/$scope_id $role $member"
                            ;;
                        "project")
                            local resource_key="${scope_id}::${role}"
                            local resource_name="module.crowdstrike_gcp_registration.module.asset-inventory.google_project_iam_member.crowdstrike_project[\"$resource_key\"]"
                            local import_id="$scope_id $role $member"
                            ;;
                    esac

                    if [[ "$DRY_RUN" == "true" ]]; then
                        echo "[DRY RUN] terraform import \"$resource_name\" \"$import_id\""
                    else
                        cd "$TERRAFORM_DIR"
                        if terraform import "$resource_name" "$import_id" >/dev/null 2>&1; then
                            echo "Successfully imported IAM binding: $role"
                        else
                            echo "Failed to import IAM binding: $role"
                            terraform import "$resource_name" "$import_id" || true
                        fi
                        cd - > /dev/null
                    fi
                fi
            fi
        done <<< "$crowdstrike_bindings"
    }

    # Import based on registration type
    if [[ "$REGISTRATION_TYPE" == "organization" && -n "$ORGANIZATION_ID" ]]; then
        import_discovered_iam_bindings "organization" "$ORGANIZATION_ID"
    elif [[ "$REGISTRATION_TYPE" == "folder" && -n "$FOLDER_IDS" ]]; then
        for folder_id in $FOLDER_IDS; do
            import_discovered_iam_bindings "folder" "$folder_id"
        done
    elif [[ "$REGISTRATION_TYPE" == "project" && -n "$PROJECT_IDS" ]]; then
        for project_id in $PROJECT_IDS; do
            import_discovered_iam_bindings "project" "$project_id"
        done
    else
        echo "No valid registration scope found for asset inventory import"
    fi
}

import_log_ingestion_resources() {
    echo "=== Importing Log Ingestion Resources ==="

    registration_id="$1"
    topic_name="${RESOURCE_PREFIX}CrowdStrikeLogTopic-${registration_id}${RESOURCE_SUFFIX}"
    subscription_name="${RESOURCE_PREFIX}CrowdStrikeLogSubscription-${registration_id}${RESOURCE_SUFFIX}"
    schema_name="${RESOURCE_PREFIX}CrowdStrikeLogSchema${RESOURCE_SUFFIX}"

    # Import Pub/Sub schema if it exists
    if gcloud pubsub schemas describe "$schema_name" --project="$INFRA_PROJECT_ID" >/dev/null 2>&1; then
        local schema_resource="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_pubsub_schema.crowdstrike_logs[0]"
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] terraform import \"$schema_resource\" \"projects/$INFRA_PROJECT_ID/schemas/$schema_name\""
        else
            cd "$TERRAFORM_DIR"
            if terraform import "$schema_resource" "projects/$INFRA_PROJECT_ID/schemas/$schema_name" >/dev/null 2>&1; then
                echo "Successfully imported Pub/Sub schema: $schema_name"
            else
                echo "Failed to import Pub/Sub schema: $schema_name"
                terraform import "$schema_resource" "projects/$INFRA_PROJECT_ID/schemas/$schema_name" || true
            fi
            cd - > /dev/null
        fi
    else
        echo "Pub/Sub schema not found: $schema_name"
    fi

    # Import Pub/Sub topic if it exists
    if gcloud pubsub topics describe "$topic_name" --project="$INFRA_PROJECT_ID" >/dev/null 2>&1; then
        local topic_resource="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_pubsub_topic.crowdstrike_logs[0]"
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] terraform import \"$topic_resource\" \"projects/$INFRA_PROJECT_ID/topics/$topic_name\""
        else
            cd "$TERRAFORM_DIR"
            if terraform import "$topic_resource" "projects/$INFRA_PROJECT_ID/topics/$topic_name" >/dev/null 2>&1; then
                echo "Successfully imported Pub/Sub topic: $topic_name"
            else
                echo "Failed to import Pub/Sub topic: $topic_name"
                terraform import "$topic_resource" "projects/$INFRA_PROJECT_ID/topics/$topic_name" || true
            fi
            cd - > /dev/null
        fi
    else
        echo "Pub/Sub topic not found: $topic_name"
    fi

    # Import Pub/Sub subscription if it exists
    if gcloud pubsub subscriptions describe "$subscription_name" --project="$INFRA_PROJECT_ID" >/dev/null 2>&1; then
        local subscription_resource="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_pubsub_subscription.crowdstrike_logs[0]"
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] terraform import \"$subscription_resource\" \"projects/$INFRA_PROJECT_ID/subscriptions/$subscription_name\""
        else
            cd "$TERRAFORM_DIR"
            if terraform import "$subscription_resource" "projects/$INFRA_PROJECT_ID/subscriptions/$subscription_name" >/dev/null 2>&1; then
                echo "Successfully imported Pub/Sub subscription: $subscription_name"
            else
                echo "Failed to import Pub/Sub subscription: $subscription_name"
                terraform import "$subscription_resource" "projects/$INFRA_PROJECT_ID/subscriptions/$subscription_name" || true
            fi
            cd - > /dev/null
        fi
    else
        echo "Pub/Sub subscription not found: $subscription_name"
    fi

    # Import log sinks based on registration type
    sink_name="${RESOURCE_PREFIX}CrowdStrikeLogSink${RESOURCE_SUFFIX}"

    case "$REGISTRATION_TYPE" in
    "organization")
        if [[ -n "$ORGANIZATION_ID" ]]; then
            if gcloud logging sinks describe "$sink_name" --organization="$ORGANIZATION_ID" >/dev/null 2>&1; then
                local sink_resource="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_logging_organization_sink.crowdstrike_logs[0]"

                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] terraform import \"$sink_resource\" \"organizations/$ORGANIZATION_ID/sinks/$sink_name\""
                else
                    cd "$TERRAFORM_DIR"
                    if terraform import "$sink_resource" "organizations/$ORGANIZATION_ID/sinks/$sink_name" >/dev/null 2>&1; then
                        echo "Successfully imported organization log sink: $sink_name"
                    else
                        echo "Failed to import organization log sink: $sink_name"
                        terraform import "$sink_resource" "organizations/$ORGANIZATION_ID/sinks/$sink_name" || true
                    fi
                    cd - > /dev/null
                fi
            fi
        fi
        ;;
    "folder")
        for folder_id in $FOLDER_IDS; do
            sink_name_with_folder="${sink_name}-${folder_id}"
            if gcloud logging sinks describe "$sink_name_with_folder" --folder="$folder_id" >/dev/null 2>&1; then
                local sink_resource="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_logging_folder_sink.crowdstrike_logs[\"$folder_id\"]"

                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] terraform import \"$sink_resource\" \"folders/$folder_id/sinks/$sink_name_with_folder\""
                else
                    cd "$TERRAFORM_DIR"
                    if terraform import "$sink_resource" "folders/$folder_id/sinks/$sink_name_with_folder" >/dev/null 2>&1; then
                        echo "Successfully imported folder log sink: $sink_name_with_folder"
                    else
                        echo "Failed to import folder log sink: $sink_name_with_folder"
                        terraform import "$sink_resource" "folders/$folder_id/sinks/$sink_name_with_folder" || true
                    fi
                    cd - > /dev/null
                fi
            fi
        done
        ;;
    "project")
        for project_id in $PROJECT_IDS; do
            sink_name_with_project="${sink_name}-${project_id}"
            if gcloud logging sinks describe "$sink_name_with_project" --project="$project_id" >/dev/null 2>&1; then
                local sink_resource="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_logging_project_sink.crowdstrike_logs[\"$project_id\"]"

                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] terraform import \"$sink_resource\" \"projects/$project_id/sinks/$sink_name_with_project\""
                else
                    cd "$TERRAFORM_DIR"
                    if terraform import "$sink_resource" "projects/$project_id/sinks/$sink_name_with_project" >/dev/null 2>&1; then
                        echo "Successfully imported project log sink: $sink_name_with_project"
                    else
                        echo "Failed to import project log sink: $sink_name_with_project"
                        terraform import "$sink_resource" "projects/$project_id/sinks/$sink_name_with_project" || true
                    fi
                    cd - > /dev/null
                fi
            fi
        done
        ;;
    esac

    # Import Pub/Sub IAM bindings for log ingestion
    if [[ -n "$topic_name" && -n "$subscription_name" ]]; then

        # Import Pub/Sub topic IAM bindings
        topic_policy=$(gcloud pubsub topics get-iam-policy "$topic_name" --project="$INFRA_PROJECT_ID" --format=json 2>/dev/null || echo '{"bindings":[]}')
        topic_bindings=$(echo "$topic_policy" | jq -r '.bindings[] | .role as $role | .members[] | "\($role)||||" + .' 2>/dev/null || true)

        while read -r binding; do
            if [[ -n "$binding" ]]; then
                role=$(echo "$binding" | cut -d'|' -f1)
                member=$(echo "$binding" | cut -d'|' -f5-)

                # Determine resource name based on member type
                if [[ "$member" == *"$REGISTRATION_ID"* ]]; then
                    # CrowdStrike viewer binding
                    local resource_name="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_pubsub_topic_iam_member.crowdstrike_viewer"
                elif [[ "$member" == *"@gcp-sa-logging"* ]]; then
                    case "$REGISTRATION_TYPE" in
                        "organization")
                            local resource_name="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_pubsub_topic_iam_member.log_writer_org[0]"
                            ;;
                        "folder")
                            folder_id=$(echo "$member" | sed 's/.*service-folder-\([0-9]*\)@.*/\1/')
                            local resource_name="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_pubsub_topic_iam_member.log_writer_folder[\"$folder_id\"]"
                            ;;
                        "project")
                            project_number=$(echo "$member" | sed 's/.*service-\([^@]*\)@.*/\1/')
                            project_id=""
                            for pid in $PROJECT_IDS; do
                                pid_number=$(gcloud projects describe "$pid" --format="value(projectNumber)" 2>/dev/null || echo "")
                                if [[ "$pid_number" == "$project_number" ]]; then
                                    project_id="$pid"
                                    break
                                fi
                            done

                            if [[ -z "$project_id" ]]; then
                                continue
                            fi

                            local resource_name="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_pubsub_topic_iam_member.log_writer_project[\"$project_id\"]"
                            ;;
                        *)
                            continue
                            ;;
                    esac
                else
                    continue
                fi

                local import_id="projects/$INFRA_PROJECT_ID/topics/$topic_name $role $member"

                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] terraform import \"$resource_name\" \"$import_id\""
                else
                    cd "$TERRAFORM_DIR"
                    if terraform import "$resource_name" "$import_id" >/dev/null 2>&1; then
                        echo "Successfully imported Pub/Sub topic IAM binding: $role"
                    else
                        echo "Failed to import Pub/Sub topic IAM binding: $role"
                        terraform import "$resource_name" "$import_id" || true
                    fi
                    cd - > /dev/null
                fi
            fi
        done <<< "$topic_bindings"

        # Import Pub/Sub subscription IAM bindings
        sub_policy=$(gcloud pubsub subscriptions get-iam-policy "$subscription_name" --project="$INFRA_PROJECT_ID" --format=json 2>/dev/null || echo '{"bindings":[]}')
        sub_bindings=$(echo "$sub_policy" | jq -r --arg reg_id "$REGISTRATION_ID" '.bindings[] | select(.members[]? | contains($reg_id)) | .role as $role | .members[] | select(contains($reg_id)) | "\($role)||||" + .' 2>/dev/null || true)

        while read -r binding; do
            if [[ -n "$binding" ]]; then
                role=$(echo "$binding" | cut -d'|' -f1)
                member=$(echo "$binding" | cut -d'|' -f5-)

                local resource_name="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_pubsub_subscription_iam_member.crowdstrike_subscriber"
                local import_id="projects/$INFRA_PROJECT_ID/subscriptions/$subscription_name $role $member"

                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "[DRY RUN] terraform import \"$resource_name\" \"$import_id\""
                else
                    cd "$TERRAFORM_DIR"
                    if terraform import "$resource_name" "$import_id" >/dev/null 2>&1; then
                        echo "Successfully imported Pub/Sub subscription IAM binding: $role"
                    else
                        echo "Failed to import Pub/Sub subscription IAM binding: $role"
                        terraform import "$resource_name" "$import_id" || true
                    fi
                    cd - > /dev/null
                fi
            fi
        done <<< "$sub_bindings"

        # Import project-level monitoring.viewer IAM binding (skip from asset inventory)
        project_policy=$(gcloud projects get-iam-policy "$INFRA_PROJECT_ID" --format=json 2>/dev/null || echo '{"bindings":[]}')
        monitoring_binding=$(echo "$project_policy" | jq -r --arg reg_id "$REGISTRATION_ID" '.bindings[] | select(.role == "roles/monitoring.viewer" and (.members[]? | contains($reg_id))) | .role as $role | .members[] | select(contains($reg_id)) | "\($role)||||" + .' 2>/dev/null || true)

        if [[ -n "$monitoring_binding" ]]; then
            role=$(echo "$monitoring_binding" | cut -d'|' -f1)
            member=$(echo "$monitoring_binding" | cut -d'|' -f5-)

            local resource_name="module.crowdstrike_gcp_registration.module.log-ingestion[0].google_project_iam_member.crowdstrike_monitoring_viewer"
            local import_id="$INFRA_PROJECT_ID $role $member"

            if [[ "$DRY_RUN" == "true" ]]; then
                echo "[DRY RUN] terraform import \"$resource_name\" \"$import_id\""
            else
                cd "$TERRAFORM_DIR"
                if terraform import "$resource_name" "$import_id" >/dev/null 2>&1; then
                    echo "Successfully imported monitoring.viewer IAM binding"
                else
                    echo "Failed to import monitoring.viewer IAM binding"
                    terraform import "$resource_name" "$import_id" || true
                fi
                cd - > /dev/null
            fi
        fi
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

echo "=== Starting Resource Import ==="
echo "This will import orphaned GCP resources back into Terraform state."
echo "Working directory: $TERRAFORM_DIR"
echo
initialize_import_context
echo
import_crowdstrike_resources
echo
import_wif_resources
echo
import_asset_inventory_resources
echo
import_log_ingestion_resources "$REGISTRATION_ID"
echo
echo "=== Import Complete ==="
echo
echo "Next steps:"
echo "1. Run 'terraform plan' to see what changes Terraform would make"
echo "2. Run 'terraform apply' to bring resources into compliance with your configuration"
echo "3. Or run 'terraform destroy' if you want to remove the imported resources"
