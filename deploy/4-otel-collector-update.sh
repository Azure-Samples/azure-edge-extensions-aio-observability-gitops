#! /bin/bash

set -e

if [ -z "$CLUSTER_NAME" ]; then
    echo "CLUSTER_NAME is not set"
    exit 1
fi
if [ -z "$RESOURCE_GROUP" ]; then
    echo "RESOURCE_GROUP is not set"
    exit 1
fi

# Variables
scriptPath=$(dirname $0)
random=$RANDOM
deploymentName="deployment-$random"

echo "Updating aio-otel-collector configuration using Bicep"
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --name aio-otel-collector-$deploymentName \
    --template-file "$scriptPath/templates/aio-otel-collector-update.bicep" \
    --parameters clusterName=$CLUSTER_NAME \
    --parameters location=$LOCATION \
    --no-prompt