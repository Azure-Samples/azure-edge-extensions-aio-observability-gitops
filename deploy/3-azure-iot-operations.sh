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
cli_pinned_version="1.0.0"

# AIO Pin the version
# Check az iot ops extension version and upgrade to version as pinned $cli_pinned_version
installed_version=$(az extension show --name azure-iot-ops --query version -o tsv)
if [ -z "$installed_version" ] || [ "$installed_version" != "$cli_pinned_version" ]; then
    echo "Azure IoT Operations extension is not installed or not the required version ($cli_pinned_version) - removing and installing"
    az extension remove --name azure-iot-ops
    az extension add --name azure-iot-ops --version "$cli_pinned_version"
else
    echo "Azure IoT Operations extension is installed with version $cli_pinned_version"
fi

# Create Schema Registry and pre-requisites
echo "Creating Storage account for schema registry"
storage_account_id=$(az storage account create --name $STORAGE_ACCOUNT --location $LOCATION --resource-group $RESOURCE_GROUP --enable-hierarchical-namespace  -o tsv --query id)
echo "Creating Schema registry"
az iot ops schema registry create --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP --registry-namespace $SCHEMA_REGISTRY_NAMESPACE --sa-resource-id $storage_account_id

# Initialize Azure IoT Operations
echo "Running Azure IoT Operations initialization"
az iot ops init --cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP

# Deploy instance
echo "Running Azure IoT Operations instance creation"
az iot ops create --cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP \
    --name ${CLUSTER_NAME}-instance \
    --sr-resource-id $(az iot ops schema registry show --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP -o tsv --query id) \
    --broker-frontend-replicas 1 --broker-frontend-workers 1  --broker-backend-part 1  --broker-backend-workers 1 --broker-backend-rf 2 --broker-mem-profile Low \
    --ops-config observability.metrics.openTelemetryCollectorAddress=otel-collector.opentelemetry.svc.cluster.local:4317 \
    --ops-config observability.metrics.exportInternalSeconds=60 \
    --ops-config connectors.values.openTelemetry.endpoints.default.emitLogs=true \
    --ops-config connectors.values.openTelemetry.endpoints.default.emitMetrics=true \
    --ops-config connectors.values.openTelemetry.endpoints.default.emitTraces=true \
    --ops-config connectors.values.openTelemetry.endpoints.default.protocol=grpc \
    --ops-config connectors.values.openTelemetry.endpoints.default.uri=http://otel-collector.opentelemetry.svc.cluster.local:4317

# Check Broker is running - when using CLI to deploy AIO, the broker is named 'default'
status=$(kubectl get broker default -n $DEFAULT_NAMESPACE -o json | jq '.status.runtimeStatus.status')
while [ "$status" != "\"Running\"" ]
do
    echo "Waiting for MQ broker to be running"
    sleep 5
    status=$(kubectl get broker default -n $DEFAULT_NAMESPACE -o json | jq '.status.runtimeStatus.status')
done

echo "MQ Broker is now running"

# Deploy OPC PLC Simulator 
kubectl apply -f "$scriptPath/yaml/opc-plc.yaml"

# OPC AssetEndpointProfile and Assets with a Bicep template
echo "Deploying OPC AssetEndpointProfile and Asset using Bicep"
custom_location_name=$(az customlocation list --resource-group $RESOURCE_GROUP --query "[?contains(name, 'location-')].[name]" -o tsv)

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --name assets-$deploymentName \
    --template-file "$scriptPath/templates/assets-endpoint.bicep" \
    --parameters clusterName=$CLUSTER_NAME \
    --parameters location=$LOCATION \
    --parameters customLocationName=$custom_location_name \
    --no-prompt

echo "Finished deploying Azure IoT Operations ${cli_pinned_version} components to cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP"