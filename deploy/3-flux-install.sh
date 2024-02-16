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

az provider register --namespace Microsoft.ContainerService

az extension add -n k8s-configuration
az extension add -n k8s-extension

az k8s-configuration flux create \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name gitops-repo \
    --namespace flux-system \
    --cluster-type connectedClusters \
    --scope cluster \
    --url https://github.com/Azure-Samples/azure-edge-extensions-aio-observability-gitops \
    --branch main  \
    --kustomization name=bootstrap path=./clusters/dev/flux prune=true
