#!/bin/bash

# Universal Infrastructure Manager Service Principal Setup Script
# Supports PROJECT/FOLDER/ORGANIZATION registration with optional RTV&D

set -e

# Script usage
usage() {
    echo "Usage: $0 --name <service-account-name> --infra-project-id <project-id> [scope-options] [other-options]"
    echo ""
    echo "Required parameters:"
    echo "  --name                Service account name for Infrastructure Manager"
    echo "  --infra-project-id    GCP project ID where Infrastructure Manager runs"
    echo ""
    echo "Registration scope (provide exactly one):"
    echo "  --organization-id     Organization ID (for organization registration)"
    echo "  --folder-ids          Comma-separated list of folder IDs (for folder registration)"
    echo "  --project-ids         Comma-separated list of target project IDs (for project registration)"
    echo ""
    echo "Optional parameters:"
    echo "  --enable-rtvd         Enable Real Time Visibility & Detection (default: false)"
    echo "  --location            Infrastructure Manager location (default: us-central1)"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Project registration with RTV&D"
    echo "  $0 --name my-sa --infra-project-id my-project --enable-rtvd --project-ids \"proj1,proj2\""
    echo ""
    echo "  # Multiple folder registration"
    echo "  $0 --name my-sa --infra-project-id my-project --folder-ids \"folders/456789,folders/789012\""
    echo ""
    echo "  # Organization registration with RTV&D"
    echo "  $0 --name my-sa --infra-project-id my-project --organization-id 123456789 --enable-rtvd"
}

# Default values
REGISTRATION_TYPE=""
PROJECT_ID=""
ENABLE_RTVD=false
ORGANIZATION_ID=""
FOLDER_IDS=""
TARGET_PROJECTS=""
SERVICE_ACCOUNT_NAME=""
LOCATION="us-central1"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --infra-project-id)
            INFRA_PROJECT_ID="$2"
            shift 2
            ;;
        --enable-rtvd)
            ENABLE_RTVD=true
            shift
            ;;
        --organization-id)
            ORGANIZATION_ID="$2"
            shift 2
            ;;
        --folder-ids)
            FOLDER_IDS="$2"
            shift 2
            ;;
        --project-ids)
            TARGET_PROJECTS="$2"
            shift 2
            ;;
        --name)
            SERVICE_ACCOUNT_NAME="$2"
            shift 2
            ;;
        --location)
            LOCATION="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown parameter: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SERVICE_ACCOUNT_NAME" ]]; then
    echo "Error: --name is required"
    usage
    exit 1
fi

if [[ -z "$INFRA_PROJECT_ID" ]]; then
    echo "Error: --infra-project-id is required"
    usage
    exit 1
fi

# Determine registration type based on provided scope parameters
SCOPE_PARAMS=0
[[ -n "$ORGANIZATION_ID" ]] && SCOPE_PARAMS=$((SCOPE_PARAMS + 1))
[[ -n "$FOLDER_IDS" ]] && SCOPE_PARAMS=$((SCOPE_PARAMS + 1))
[[ -n "$TARGET_PROJECTS" ]] && SCOPE_PARAMS=$((SCOPE_PARAMS + 1))

if [[ $SCOPE_PARAMS -eq 0 ]]; then
    echo "Error: Must provide exactly one scope parameter: --organization-id, --folder-ids, or --project-ids"
    usage
    exit 1
elif [[ $SCOPE_PARAMS -gt 1 ]]; then
    echo "Error: Cannot provide multiple scope parameters. Choose one: --organization-id, --folder-ids, or --project-ids"
    usage
    exit 1
fi

# Set registration type based on which parameter was provided
if [[ -n "$ORGANIZATION_ID" ]]; then
    REGISTRATION_TYPE="organization"
elif [[ -n "$FOLDER_IDS" ]]; then
    REGISTRATION_TYPE="folder"
elif [[ -n "$TARGET_PROJECTS" ]]; then
    REGISTRATION_TYPE="project"
fi

# Derived variables
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${INFRA_PROJECT_ID}.iam.gserviceaccount.com"

# Create service account
echo "Creating Infrastructure Manager service account..."
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
    --display-name="Infrastructure Manager Service Account" \
    --project=$INFRA_PROJECT_ID || echo "Service account may already exist"

echo "Waiting for service account propagation..."
sleep 5
echo

# Enable base APIs
echo "Enabling base Infrastructure Manager APIs..."
BASE_APIS=(
    "config.googleapis.com"
    "serviceusage.googleapis.com"
    "iam.googleapis.com"
    "iamcredentials.googleapis.com"
    "sts.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "cloudasset.googleapis.com"
)

for api in "${BASE_APIS[@]}"; do
    echo "  Enabling $api..."
    gcloud services enable "$api" --project=$INFRA_PROJECT_ID
done

# Enable RTV&D APIs if requested
if [[ "$ENABLE_RTVD" == true ]]; then
    echo "Enabling RTV&D APIs..."
    RTVD_APIS=(
        "logging.googleapis.com"
        "monitoring.googleapis.com"
        "pubsub.googleapis.com"
    )

    for api in "${RTVD_APIS[@]}"; do
        echo "  Enabling $api..."
        gcloud services enable "$api" --project=$INFRA_PROJECT_ID
    done
fi

echo

# Apply roles based on registration type
echo "Applying IAM roles for $REGISTRATION_TYPE registration..."

# Project-level roles (common to all registration types)
PROJECT_ROLES=(
    "roles/config.agent"
    "roles/iam.workloadIdentityPoolAdmin"
)

# Add registration-type specific project roles
case $REGISTRATION_TYPE in
    "project")
        PROJECT_ROLES+=(
            "roles/browser"
            "roles/resourcemanager.projectIamAdmin"
            "roles/serviceusage.serviceUsageAdmin"
        )
        ;;
    "folder")
        PROJECT_ROLES+=(
            "roles/serviceusage.serviceUsageAdmin"
        )
        ;;
    "organization")
        # No additional project roles for org registration
        ;;
esac

# Add RTV&D project roles if enabled
if [[ "$ENABLE_RTVD" == true ]]; then
    PROJECT_ROLES+=(
        "roles/pubsub.admin"
    )

    # Add logging role for all registration types with RTV&D
    if [[ "$REGISTRATION_TYPE" == "project" ]]; then
        PROJECT_ROLES+=(
            "roles/logging.configWriter"
        )
    fi

    # Add projectIamAdmin for folder/org with RTV&D
    if [[ "$REGISTRATION_TYPE" != "project" ]]; then
        PROJECT_ROLES+=(
            "roles/resourcemanager.projectIamAdmin"
        )
    fi
fi

# Apply project-level roles
echo "Applying project-level roles..."
for role in "${PROJECT_ROLES[@]}"; do
    echo "  Binding $role..."
    gcloud projects add-iam-policy-binding $INFRA_PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role"
done

# Apply folder-level roles (for multiple folders)
if [[ "$REGISTRATION_TYPE" == "folder" ]]; then
    echo "Applying folder-level roles..."
    FOLDER_ROLES=(
        "roles/browser"
        "roles/resourcemanager.folderIamAdmin"
    )

    # Add RTV&D folder roles
    if [[ "$ENABLE_RTVD" == true ]]; then
        FOLDER_ROLES+=(
            "roles/logging.configWriter"
        )
    fi

    # Process multiple folders
    IFS=',' read -ra FOLDER_ARRAY <<< "$FOLDER_IDS"
    for folder in "${FOLDER_ARRAY[@]}"; do
        folder=$(echo "$folder" | xargs) # trim whitespace
        echo "  Processing folder: $folder"

        for role in "${FOLDER_ROLES[@]}"; do
            echo "    Binding $role to folder $folder..."
            gcloud resource-manager folders add-iam-policy-binding "$folder" \
                --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
                --role="$role"
            sleep 2
        done
    done
fi

# Apply organization-level roles
if [[ "$REGISTRATION_TYPE" == "organization" ]]; then
    echo "Applying organization-level roles..."
    ORG_ROLES=(
        "roles/browser"
        "roles/resourcemanager.organizationAdmin"
        "roles/serviceusage.serviceUsageAdmin"
    )

    # Add RTV&D org roles
    if [[ "$ENABLE_RTVD" == true ]]; then
        ORG_ROLES+=(
            "roles/logging.configWriter"
        )
    fi

    for role in "${ORG_ROLES[@]}"; do
        echo "  Binding $role to organization $ORGANIZATION_ID..."
        gcloud organizations add-iam-policy-binding $ORGANIZATION_ID \
            --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
            --role="$role"
        sleep 3
    done
fi

# Apply target project permissions (for project registration)
if [[ "$REGISTRATION_TYPE" == "project" && -n "$TARGET_PROJECTS" ]]; then
    echo "Applying permissions to target projects..."
    IFS=',' read -ra PROJ_ARRAY <<< "$TARGET_PROJECTS"
    for project in "${PROJ_ARRAY[@]}"; do
        project=$(echo "$project" | xargs) # trim whitespace
        echo "  Applying Owner role to project: $project"
        gcloud projects add-iam-policy-binding "$project" \
            --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
            --role="roles/owner"
    done
fi

echo
echo "=== Setup Complete ==="
echo "Service Account: $SERVICE_ACCOUNT_EMAIL"
