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
if [ -z "$ARC_CUSTOMLOCATION_OID" ]; then
    echo "ARC_CUSTOMLOCATION_OID is not set"
    exit 1
fi

az provider register -n "Microsoft.ExtendedLocation"
az provider register -n "Microsoft.Kubernetes"
az provider register -n "Microsoft.KubernetesConfiguration"
az provider register -n "Microsoft.IoTOperations"
az provider register -n "Microsoft.DeviceRegistry"

az group create --name $RESOURCE_GROUP --location $LOCATION

# try connecting to Arc, if it fails, continue with debug code
set +e

echo "Connecting the local K3S cluster to Azure Arc"
az connectedk8s connect --name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION

status=$?

set -e

if [ $status -ne 0 ]; then
  echo "Failed to connect to Arc, continuing with debug code"
  kubectl get all -n azure-arc
  # loop and print through all logs for pre-boarding checks for debugging
  for entry in "/home/codespace/.azure/pre_onboarding_check_logs"/*
  do
    if [ -d "$entry" ]; then
        for child in "$entry"/*
        do
            echo "-------------------------"
            echo "$child"
            cat "$child"
        done
    else
        echo "-------------------------"
        echo "$entry"
        cat "$entry"
    fi
  done
  exit 1

fi

kubectl get ns
kubectl get all -n azure-arc

az connectedk8s enable-features -n $CLUSTER_NAME -g $RESOURCE_GROUP --custom-locations-oid $ARC_CUSTOMLOCATION_OID --features cluster-connect custom-locations

echo "Arc connceted to cluster $CLUSTER_NAME"
