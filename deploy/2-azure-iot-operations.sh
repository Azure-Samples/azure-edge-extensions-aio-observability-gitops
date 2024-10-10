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
cli_pinned_version="0.7.0b1"

# AIO Preview update
# Check az iot ops extension version and upgrade to version as pinned $cli_pinned_version
installed_version=$(az extension show --name azure-iot-ops --query version -o tsv)
if [ -z "$installed_version" ] || [ "$installed_version" != "$cli_pinned_version" ]; then
    echo "Azure IoT Operations Preview extension is not installed or not the required version ($cli_pinned_version) - removing and installing"
    az extension remove --name azure-iot-ops
    az extension add --name azure-iot-ops --version "$cli_pinned_version"
else
    echo "Azure IoT Operations Preview extension is installed with version $cli_pinned_version"
fi

# Create Schema Registry and pre-requisites
echo "Creating Storage account for schema registry"
storage_account_id=$(az storage account create --name $STORAGE_ACCOUNT --location $LOCATION --resource-group $RESOURCE_GROUP --enable-hierarchical-namespace  -o tsv --query id)
echo "Creating Schema registry"
az iot ops schema registry create --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP --registry-namespace $SCHEMA_REGISTRY_NAMESPACE --sa-resource-id $storage_account_id

# Initialize Azure IoT Operations
echo "Running Azure IoT Operations initialization"
az iot ops init --cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP --sr-resource-id $(az iot ops schema registry show --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP -o tsv --query id)

# Deploy instance # TODO see tls-listener insecure + resource sync disabled
echo "Running Azure IoT Operations instance creation"
az iot ops create --cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP --name ${CLUSTER_NAME}-instance

# Deploy OPC PLC simulator (Note this can move to FLUX based setup once GA, but skip for this Preview version)
echo "Deploying OPC PLC Simulator"
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/explore-iot-operations/main/samples/quickstarts/opc-plc-deployment.yaml

# Create Key Vault
# echo "Create Key Vault"
# az keyvault create -n $AKV_NAME -g $RESOURCE_GROUP --enable-rbac-authorization false
# keyVaultResourceId=$(az keyvault show -n $AKV_NAME -g $RESOURCE_GROUP -o tsv --query id)

# # Initialize Azure IoT Operations Preview Pre-requisites
# # This will install Azure Arc Extension CSI Driver, configure TLS and some Secrets and ConfigMaps
# echo "Initializing Azure IoT Operations pre-requisites with the Azure IoT CLI extension"
# az iot ops init --cluster $CLUSTER_NAME -g $RESOURCE_GROUP  \
#   --kv-id $keyVaultResourceId \
#   --no-deploy

# echo "Installing Azure IoT Operations Preview components using ARM template to customize some settings"
# echo "Settings include:"
# echo "- OPCUA - set to true "connectors.opcua.values.openTelemetry.endpoints.default.emitLogs": "true", "
# echo "- Removed the deployment of Otel Collector in default template, will do this in step 4"
# # Removed the "[variables('observability_helmChart')]" from the target '[parameters('targetName')]'"
# az deployment group create \
#     --resource-group $RESOURCE_GROUP \
#     --name aio-$deploymentName \
#     --template-file "$scriptPath/templates/azureiotops-edited.json" \
#     --parameters clusterName=$CLUSTER_NAME \
#     --parameters location=$LOCATION \
#     --parameters clusterLocation=$LOCATION \
#     --parameters deployResourceSyncRules=true \
#     --parameters simulatePLC=true \
#     --no-prompt

# Add a Developer endpoint non TLS for MQ - local testing
# # Never do the below in production!!
# echo "Local dev - adding a non-TLS BrokerListener for port 1883"
# kubectl apply -f $scriptPath/yaml/mq-listener-non-tls.yaml 
# Never do the above in production!!

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