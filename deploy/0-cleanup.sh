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
k3d cluster delete devcluster

k3d cluster create devcluster -p '1883:1883@loadbalancer'

echo "Finished delete Resource Group and re-created K3D cluster"