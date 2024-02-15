# Sample with Azure IoT Operations Preview and Local Observability with OpenTelemetry and GitOps

This sample focuses on the deployment of
A Visual Studio Code dev container is used as the developer sandbox to leverage a local K3D cluster, initialize Azure resources and install a baseline set of Azure IoT Operations' components.

> [!WARNING]
Azure IoT Operations is still in Preview. Any parts of sample could stop working as the product evolves towards General Availability.

## Features

This project framework provides the following features:

* Feature 1
* Feature 2
* ...

## Getting Started

### Prerequisites

* Visual Studio Code
* Dev Containers support in Visual Studio Code
* Azure subscription
* Azure account with Owner permissions on the Subscription
* Docker runtime

### Installation

We recommend you fork this project in GitHub and then clone your fork in order to setup GitOps linking to your own fork. This will enable you to apply changes and experiment more easily.

By using the Dev Container, a K3D cluster and any documented client tools will be automatically installed and ready to use for testing out the sample.

* Fork this repository in GitHub.
* Clone your fork locally.
* Open the project with Visual Studio Code.
* Launch the Dev Container with Command Palette > `Dev Containers: Reopen in Container`.
* Log into Azure and set your default subscription.

  ```bash
  az login --tenant <your tenant ID or domain>

  az account set -s <your subscription ID or name>`
  ```

* Prepare the following inputs to create environment variables in the next step:
  * `ARC_CUSTOMLOCATION_OID`: retrieve the unique Custom location Object ID for your tenant by running `az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv`
  * `TENANT_ID`: your Microsoft Entra ID Tenant ID
  * `LOCATION`: make sure you choose something from the supported list of regions as documented in [Deploy Azure IoT Operations, see Location table](https://learn.microsoft.com/en-us/azure/iot-operations/get-started/quickstart-deploy?tabs=codespaces#connect-a-kubernetes-cluster-to-azure-arc)
  * Use your preferred Azure resource names where you can find the `...` in the variable contents

* Create a new file to load environment variables under `./temp/envvars.sh`, with the following contents:

  ```bash
  # change the below set to match your environment
  export RESOURCE_GROUP=rg-...
  export CLUSTER_NAME=arck-...
  export AKV_NAME=kv-...
  export TENANT_ID="<>"
  export LOCATION=northeurope # your choice
  export ARC_CUSTOMLOCATION_OID="<>"
  export DEFAULT_NAMESPACE=azure-iot-operations # do not change
  ```

* Load the environment variables in your terminal by running:

  ```bash
  source ./temp/envvars.sh
  ```

### Quickstart

To enable the local K3D cluster to Azure Arc and install Azure IoT Operations with the default components and configuration.

1. Open a `bash` terminal and leave it in the default root folder `/workspaces/azure-edge-extensions-aio-observability-gitops`.
1. Run the script `./deploy/1-arc-k8s-connect.sh`. This will take a few minutes.
1. Tun the script `./deploy/2-azure-iot-operations.sh`. Grab a coffee, this can take 15 minutes.

<!-- ## Demo (TODO)

A demo app is included to show how to use the project.

To run the demo, follow these steps:

(Add steps to start up the demo)

1.
2.
3. -->

## Resources
<!-- 
(Any additional resources or related projects)

- Link to supporting information
- Link to similar sample
- ... -->
