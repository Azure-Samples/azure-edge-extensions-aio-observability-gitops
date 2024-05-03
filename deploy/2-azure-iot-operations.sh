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
if [ -z "$LOCATION" ]; then
    echo "LOCATION is not set"
    exit 1
fi
if [ -z "$AKV_NAME" ]; then
    echo "AKV_NAME is not set"
    exit 1
fi

# Variables
scriptPath=$(dirname $0)
random=$RANDOM
deploymentName="deployment-$random"

# Create Key Vault
echo "Create Key Vault"
az keyvault create -n $AKV_NAME -g $RESOURCE_GROUP --enable-rbac-authorization false
keyVaultResourceId=$(az keyvault show -n $AKV_NAME -g $RESOURCE_GROUP -o tsv --query id)

# Initialize Azure IoT Operations Preview Pre-requisites
# This will install Azure Arc Extension CSI Driver, configure TLS and some Secrets and ConfigMaps
echo "Initializing Azure IoT Operations pre-requisites with the Azure IoT CLI extension"
az iot ops init --cluster $CLUSTER_NAME -g $RESOURCE_GROUP  \
  --kv-id $keyVaultResourceId \
  --no-deploy

# Updating the AKS CSI Driver post-install - this is a workaround to disable a resource intense monitoring Pod
echo "Updating the AKS CSI Driver post-install"
az k8s-extension update --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP \
    --cluster-type connectedClusters \
    --name akvsecretsprovider \
    --configuration-settings arc.enableMonitoring=false --yes

echo "Installing Azure IoT Operations Preview components using ARM template to customize some settings"
echo "Settings include:"
echo "- MQ adding the property 'openTelemetryTracesCollectorAddr'"
echo "- OPC UA Broker extension setting 'opcPlcSimulation.autoAcceptUntrustedCertificates' property to true for testing"
echo "- Removed the deployment of Otel Collector in default template, will do this in step 4"
# Removed the "[variables('observability_helmChart')]" from the target '[parameters('targetName')]'"
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --name aio-$deploymentName \
    --template-file "$scriptPath/templates/azureiotops-edited.json" \
    --parameters clusterName=$CLUSTER_NAME \
    --parameters location=$LOCATION \
    --parameters clusterLocation=$LOCATION \
    --parameters deployResourceSyncRules=true \
    --parameters simulatePLC=true \
    --no-prompt

# Add a Developer endpoint non TLS for MQ - local testing
echo "Local dev - adding a non-TLS BrokerListener for port 1883"
kubectl apply -f $scriptPath/yaml/mq-listener-non-tls.yaml 

# Check Broker is running - when using CLI to deploy AIO, the broker is named 'broker'
status=$(kubectl get broker broker -n $DEFAULT_NAMESPACE -o json | jq '.status.status')
while [ "$status" != "\"Running\"" ]
do
    echo "Waiting for MQ broker to be running"
    sleep 5
    status=$(kubectl get broker broker -n $DEFAULT_NAMESPACE -o json | jq '.status.status')
done

echo "MQ Broker is now running"

# OPC AssetEndpointProfile and Assets with a Bicep template
echo "Deploying OPC AssetEndpointProfile and Asset using Bicep"
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --name assets-$deploymentName \
    --template-file "$scriptPath/templates/assets-endpoint.bicep" \
    --parameters clusterName=$CLUSTER_NAME \
    --parameters location=$LOCATION \
    --no-prompt

echo "Finished deploying Azure IoT Operations Preview components to cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP"