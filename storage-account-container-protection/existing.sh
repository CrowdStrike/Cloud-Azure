#!/bin/bash
export TESTS="${HOME}/testfiles"
RD="\033[1;31m"
GRN="\033[1;33m"
NC="\033[0;0m"
# shellcheck disable=SC2034
LB="\033[1;34m"

# Source the common functions
# shellcheck disable=SC1091
source ./.functions.sh

if [ -z "$1" ]; then
    echo "You must specify 'up' or 'down' to run this script"
    exit 1
fi
# shellcheck disable=SC2060
MODE=$(echo "$1" | tr [:upper:] [:lower:])
if [[ "$MODE" == "up" ]]; then
    # Get the Azure Subcription ID
    SUBSCRIPTION_ID=$(azure_get_subscription_id)
    echo "--------------------------------------------------"
    echo "Using Azure Subscription ID: $SUBSCRIPTION_ID"
    echo "--------------------------------------------------"
    read -r -sp "CrowdStrike API Client ID: " FID
    echo
    read -r -sp "CrowdStrike API Client SECRET: " FSECRET
    echo
    read -r -sp "Storage account name: " SACCOUNT
    echo
    read -r -sp "Storage account container name: " SCONTAINER
    echo
    read -r -sp "Resource group name: " RGROUP
    echo

    # Make sure variables are not empty
    if [ -z "$FID" ] || [ -z "$FSECRET" ]; then
        die "You must specify a valid CrowdStrike API Client ID and SECRET"
    fi

    # Verify the CrowdStrike API credentials
    echo "Verifying CrowdStrike API credentials..."
    # shellcheck disable=SC2034
    cs_falcon_cloud="us-1"
    response_headers=$(mktemp)
    cs_verify_auth
    # Get the base URL for the CrowdStrike API
    cs_set_base_url
    echo "Falcon Cloud URL set to: $(cs_cloud)"
    # Cleanup tmp file
    rm "${response_headers}"

    # Initialize Terraform
    if ! [ -f existing/.terraform.lock.hcl ]; then
        terraform -chdir=existing init
    fi
    # Update terraform variables
    sed -i "s/TF_STORAGE_ACCOUNT_NAME/${SACCOUNT//\//\\/}/g" ./existing/terraform.tfvars
    sed -i "s/TF_STORAGE_ACCOUNT_CONTAINER_NAME/${SCONTAINER//\//\\/}/g" ./existing/terraform.tfvars
    sed -i "s/TF_RESOURCE_GROUP/${RGROUP//\//\\/}/g" ./existing/terraform.tfvars
    # Apply Terraform
    terraform -chdir=existing apply -compact-warnings --var falcon_client_id="$FID" \
        --var falcon_client_secret="$FSECRET" \
        --var base_url="$(cs_cloud)" \
        --auto-approve
    echo -e "$GRN\nPausing for 30 seconds to allow configuration to settle.$NC"
    #sleep 30
    configure_environment "existing"
    exit 0
fi
if [[ "$MODE" == "down" ]]; then
    # Destroy Terraform
    success=1
    while [ $success -ne 0 ]; do
        terraform -chdir=existing destroy -compact-warnings --auto-approve
        success=$?
        if [ $success -ne 0 ]; then
            echo -e "$RD\nTerraform destroy failed. Retrying in 5 seconds.$NC"
            sleep 5
        fi
    done
    rm ./bin/get-findings ./bin/upload ./bin/list-bucket 2>/dev/null
    rm -rf "$TESTS" /tmp/malicious 2>/dev/null
    env_destroyed
    exit 0
fi
die "Invalid command specified."
