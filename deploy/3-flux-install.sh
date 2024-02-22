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
if [ -z "$GITOPS_SOURCE_REPO" ]; then
    GITOPS_SOURCE_REPO="https://github.com/Azure-Samples/azure-edge-extensions-aio-observability-gitops"
fi
if [ -z "$GITOPS_BRANCH" ]; then
    GITOPS_BRANCH="main"
fi

az provider register --namespace Microsoft.ContainerService

echo "Applying flux configuration"

az k8s-configuration flux create \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name gitops-repo \
    --namespace flux-system \
    --cluster-type connectedClusters \
    --scope cluster \
    --url $GITOPS_SOURCE_REPO \
    --branch $GITOPS_BRANCH \
    --kustomization name=bootstrap path=./clusters/dev/flux prune=true

echo "Successfully applied flux configuration to cluster $CLUSTER_NAME"