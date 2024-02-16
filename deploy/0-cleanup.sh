#! /bin/bash

set -e

if [ -z "$RESOURCE_GROUP" ]; then
    echo "RESOURCE_GROUP is not set"
    exit 1
fi

# Delete resource group with Key vault, Arc, and all AIO components
echo "About to delete resource group $RESOURCE_GROUP, please confirm at the next prompt"
az group delete --name $RESOURCE_GROUP

echo "Resource group $RESOURCE_GROUP deleted, now resetting the K3D cluster to a clean state"
# Reset K3D cluster
k3d registry delete devregistry.localhost  
k3d cluster delete devcluster

# Create local registry for K3D and local development
k3d registry create devregistry.localhost  --port 5500

k3d cluster create devcluster --registry-use k3d-devregistry.localhost:5500 -i ghcr.io/jlian/k3d-nfs:v1.25.3-k3s1 --env 'K3D_FIX_MOUNTS=1@server:*' \
    -p '1883:1883@loadbalancer'

echo "Finished delete Resource Group and re-created K3D cluster"