#!/bin/bash

set -eu

LOCATION=${1:?"LOCATION is unset or null"}
CONFIG_FILE=${2:?"CONFIG_FILE is unset or null"}

################################################################################
# Verify target Azure subscription
################################################################################

SUBSCRIPTION_NAME=$(az account show --query name --output tsv)

read -r -p "Create Terraform backend in Azure \
subscription '$SUBSCRIPTION_NAME'? (y/N) " response

case $response in
  [yY][eE][sS]|[yY])
    ;;
  *)
    exit 0
    ;;
esac

################################################################################
# Read Terraform backend configuration
################################################################################

if [[ -f "$CONFIG_FILE" ]]
then
  echo "Using config file '$CONFIG_FILE'."
else
  echo "Config file '$CONFIG_FILE' does not exist."
  exit 1
fi

CONFIG=$(cat "$CONFIG_FILE")

RESOURCE_GROUP_NAME=$(echo "$CONFIG" | jq -r .resource_group_name)
STORAGE_ACCOUNT_NAME=$(echo "$CONFIG" | jq -r .storage_account_name)
CONTAINER_NAME=$(echo "$CONFIG" | jq -r .container_name)

################################################################################
# Create Azure resource group
################################################################################

az group create \
  --name "${RESOURCE_GROUP_NAME}" \
  --location "${LOCATION}" \
  --output none

################################################################################
# Create Azure Storage account
################################################################################

storage_account_id="$(az storage account create \
  --name "${STORAGE_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --location "${LOCATION}" \
  --sku Standard_GRS \
  --access-tier Hot \
  --kind BlobStorage \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --allow-cross-tenant-replication false \
  --query id \
  --output tsv)"

echo "Storage account ID: $storage_account_id"

az storage account blob-service-properties update \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 30 \
  --enable-versioning true \
  --enable-change-feed true \
  --output none

az security atp storage update \
  --storage-account "${STORAGE_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --is-enabled true \
  --output none

################################################################################
# Create Azure Storage container
################################################################################

az storage container create \
  --name "${CONTAINER_NAME}" \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --auth-mode login \
  --output none

################################################################################
# Create Azure Storage lifecycle policy
################################################################################

management_policy=$(echo "$CONFIG" | jq '{
  rules: [
    {
      name: "Delete old tfstate versions",
      enabled: true,
      type: "Lifecycle",
      definition: {
        actions: {
          version: {
            delete: {
              daysAfterCreationGreaterThan: 30,
            }
          }
        },
        filters: {
          blobTypes: [
            "blockBlob"
          ],
          prefixMatch: [
            .container_name
          ]
        }
      }
    }
  ]
}')

az storage account management-policy create \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --policy "${management_policy}" \
  --output none

################################################################################
# Create Azure resource lock
################################################################################

az resource lock create \
  --name 'Terraform' \
  --lock-type CanNotDelete \
  --resource "${storage_account_id}" \
  --notes "Prevent deletion of Terraform backend" \
  --output none
