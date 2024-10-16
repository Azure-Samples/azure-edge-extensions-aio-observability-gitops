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
az iot ops init --cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP \
    --sr-resource-id $(az iot ops schema registry show --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP -o tsv --query id) \
    --ops-config observability.metrics.openTelemetryCollectorAddress=otel-collector.opentelemetry.svc.cluster.local:4317 \
    --ops-config observability.metrics.exportInternalSeconds=60

# Deploy instance
echo "Running Azure IoT Operations instance creation"
az iot ops create --cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP \
    --name ${CLUSTER_NAME}-instance \
    --broker-config-file "$scriptPath/templates/broker-config.json" \
    --add-insecure-listener

# Deploy OPC PLC simulator (Note this can move to FLUX based setup once GA, but skip for this Preview version)
echo "Deploying OPC PLC Simulator"
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/explore-iot-operations/main/samples/quickstarts/opc-plc-deployment.yaml

# Check Broker is running - when using CLI to deploy AIO, the broker is named 'default'
status=$(kubectl get broker default -n $DEFAULT_NAMESPACE -o json | jq '.status.runtimeStatus.status')
while [ "$status" != "\"Running\"" ]
do
    echo "Waiting for MQ broker to be running"
    sleep 5
    status=$(kubectl get broker default -n $DEFAULT_NAMESPACE -o json | jq '.status.runtimeStatus.status')
done

echo "MQ Broker is now running"

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

# Temporary hack to set Tracing and Logs to true in OPC UA Supervisor in v0.7.x-preview
echo "Patching OPC UA Supervisor to emit Traces and Logs"
# opcuabroker_OpenTelemetry__Endpoints__3POtelEndpoint__EmitLogs
kubectl patch deployment aio-opc-supervisor -n azure-iot-operations --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/env/57/value", "value": "true"}]'
# opcuabroker_OpenTelemetry__Endpoints__3POtelEndpoint__EmitTraces
kubectl patch deployment aio-opc-supervisor -n azure-iot-operations --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/env/59/value", "value": "true"}]'

echo "Finished deploying Azure IoT Operations Preview components to cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP"