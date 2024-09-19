#!/bin/bash

AZURE_DEFAULTS_LOCATION="polandcentral"
AZURE_DEFAULTS_GROUP="waveform-rg"
AZURE_STORAGE_ACCOUNT="waveformstorage1234"
CONTAINER_NAME="raw-waveform-data"
OUTPUT_CONTAINER_NAME="output-waveform-data"

PWDB_FILE="pwdb/PWs_AorticRoot_P_sample.csv"
MMDB_FILE="mmdb/agg_inputs_CAD_sample.csv"

DATAFACTORY_NAME="waveform-df"
GITHUB_DF_NAME="waveforms-azure-data-factory"

SUBSCRIPTION_ID=$(az account list --query "[?user.name=='jacekgrela@gmail.com'].id" --output tsv)
USER_ID=$(az ad user list --query "[?mail=='jacekgrela@gmail.com'].id" --output tsv)
SQL_NAME="waveform-sql-server"
SQL_DB="waveform_db"

#### RESOURCE GROUP
az config set defaults.location=$AZURE_DEFAULTS_LOCATION
az group create --name $AZURE_DEFAULTS_GROUP
az config set defaults.group=$AZURE_DEFAULTS_GROUP


#### STORAGE ACCOUNT + CONTAINER + UPLOAD FILES
az storage account create --name $AZURE_STORAGE_ACCOUNT --sku Standard_LRS --min-tls-version TLS1_2
AZURE_STORAGE_KEY=$(az storage account keys list --account-name $AZURE_STORAGE_ACCOUNT --query [0].value --output tsv)
az config set storage.key=$AZURE_STORAGE_KEY storage.account=$AZURE_STORAGE_ACCOUNT

az storage container create --name $CONTAINER_NAME
az storage blob upload --file $PWDB_FILE --container-name $CONTAINER_NAME --name pwdb-PWs_AorticRoot_P
az storage blob upload --file $MMDB_FILE --container-name $CONTAINER_NAME --name mmdb-agg_inputs_CAD
az storage container create --name $OUTPUT_CONTAINER_NAME

#### DATA FACTORY
az datafactory create --name $DATAFACTORY_NAME --factory-git-hub-configuration host-name=https://github.com account-name=grelade repository-name=$GITHUB_DF_NAME collaboration-branch=master root-folder=/adf

DF_MANAGEDID=$(az datafactory show --name $DATAFACTORY_NAME --query identity.principalId --output tsv)
az role assignment create --role "Storage Blob Data Contributor" --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${AZURE_DEFAULTS_GROUP}/providers/Microsoft.Storage/storageAccounts/${AZURE_STORAGE_ACCOUNT} --assignee-object-id $DF_MANAGEDID --assignee-principal-type ServicePrincipal

#### SQL SERVER + SQL DB
az sql server create --name $SQL_NAME --enable-ad-only-auth --external-admin-sid $USER_ID --external-admin-name azureuser
# az sql server create --name $SQL_NAME --admin-password $SQL_PASSWORD --admin-user $SQL_USER
az sql db create --name $SQL_DB --server $SQL_NAME --zone-redundant false --backup-storage-redundancy Local --family Gen4 --edition Basic --capacity 5 --service-level-objective Basic
az sql server firewall-rule create --server $SQL_NAME --name AllowAllWindowsAzureIps --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
