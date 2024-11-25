# Sample with Azure IoT Operations and Local Observability with OpenTelemetry and GitOps

In this sample, a Visual Studio Code dev container is used as the developer sandbox to leverage a local K3D cluster, initialize Azure resources and install a baseline set of Azure IoT Operations' components.

The objective is to illustrate how to setup observability to be able to locally visualize health of the cluster and Azure IoT Operations' components. This repository is particularly useful for those interested in edge-based visualization. More details about the setup can be found [here](./docs/observability-setup.md).

If you’re looking for a default observability setup and wish to analyze observability data using Azure Arc extensions and Azure Monitor in the cloud, follow [this documentation](https://learn.microsoft.com/en-us/azure/iot-operations/monitor/howto-configure-observability).

> [!TIP]
> This sample is compatible with Azure IoT Operations version 1.0.0.

## Getting Started

### Prerequisites

* Visual Studio Code installed on your development machine. For more information, see [Download Visual Studio Code](https://code.visualstudio.com/download).
* Dev Containers support in Visual Studio Code, or use Codespaces.
* An Azure subscription. If you don't have an Azure subscription, [create one for free](https://azure.microsoft.com/free/) before you begin.
* Azure subscription RBAC permissions: either Contributor role, or if using an existing resource group, use an identity that has **Microsoft/Authorization/roleAssignments/write**. permissions at the resource group level.
* [Docker](https://docs.docker.com/engine/install/) runtime.

### Installation

We recommend you fork this project in GitHub and clone the fork in order to setup GitOps independently from the main repo. This will enable you to apply changes and experiment more easily on your own.

By using the Dev Container, a K3D cluster and any documented client tools will be automatically installed and ready to use for testing out the sample.

1. Fork this repository in GitHub.
1. Clone your fork locally.
1. Open the project with Visual Studio Code.
1. Launch the Dev Container with Command Palette > `Dev Containers: Reopen in Container`. First time building the container may take a while.
1. Open a `bash` terminal and leave the current directory to the default root folder `/workspaces/azure-edge-extensions-aio-observability-gitops`.
1. Log into Azure and select your default subscription through the CLI interface.

   ```bash
   az login --tenant <your tenant ID or domain>

   ```

1. Run the following in the `bash` terminal to create a file in the `./temp` directory for storing and loading environment variables. This folder is excluded from Git.

   ```bash
   if [ ! -d "./temp" ]; then
         mkdir ./temp
   fi
   >./temp/envvars.sh cat <<EOF
   # change the below set to match your environment based on Readme
   export RESOURCE_GROUP=YOUR_CHOICE # For example rg-myabbrev-dev1
   export CLUSTER_NAME=YOUR_CHOICE # For example arck-myabbrev-dev1
   export AKV_NAME=YOUR_CHOICE # For example arck-myabbrev-dev1
   export STORAGE_ACCOUNT=YOUR_CHOICE # Only allows alphanumeric characters, max 32
   export SCHEMA_REGISTRY=YOUR_CHOICE # For example asr-myabbrev-dev1
   export SCHEMA_REGISTRY_NAMESPACE=YOUR_CHOICE # For example asrn-myabbrev-dev1
   export LOCATION=northeurope # replace by your choice based on available regions, see Readme
   export ARC_CUSTOMLOCATION_OID="" # see Readme
   export DEFAULT_NAMESPACE=azure-iot-operations # do not change
   export GITOPS_SOURCE_REPO="https://github.com/Azure-Samples/azure-edge-extensions-aio-observability-gitops" # change to your repo fork if you are testing your own version
   export GITOPS_BRANCH="main" # change if desired
   EOF

   code ./temp/envvars.sh

   ```

1. The newly created file `./temp/envvars.sh` should now be opened in the Code editor.
1. Update the variables in the file according to these details:

   1. For the resource names, use your preferred Azure resource names in the variable contents. An example using the recommended resource abbreviations provided in the comments
   1. `ARC_CUSTOMLOCATION_OID`: retrieve the unique Custom location Object ID for your tenant by running `az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv`
   1. `LOCATION`: make sure you choose something from the supported list of regions as documented in [Deploy Azure IoT Operations, see Location table](https://learn.microsoft.com/en-us/azure/iot-operations/get-started/quickstart-deploy?tabs=codespaces#connect-a-kubernetes-cluster-to-azure-arc)

1. Load the environment variables in your terminal by running:

  ```bash
  source ./temp/envvars.sh
  ```

### Quickstart

Enable the local K3D cluster to Azure Arc and install Azure IoT Operations with the default components and configuration.

1. In a `bash` terminal, run the script script `./deploy/1-arc-k8s-connect.sh` to connect the K3D cluster to Azure Arc. This will take a few minutes.
1. Run the script `./deploy/2-flux-install.sh` to create a [Flux](https://fluxcd.io/flux/) configuration with edge observability components and OpenTelemetry collector.
1. Run the script `./deploy/3-azure-iot-operations.sh`.

   This script installs Azure IoT Operations and adds a developer-only mode, non-TLS enabled MQ Broker listener so you can debug messages without setting up TLS from the local machine to the local cluster. This setting is for the developer inner loop and should never be done in production.

1. Validate the installation finished correctly by running `mqttui` in the terminal. You should see messages being published in the topic `azure-iot-operations`.

### View observability data

Through Flux a set of components for local edge observability was deployed to the cluster. It includes Grafana for interactive visualizations and analytics, Tempo for tracing, Loki for logging, and Prometheus for metrics.

To view the observability data, follow these steps:

1. Initiate port forwarding with the following command: `kubectl port-forward svc/grafana 3000:80 -n edge-observability`
1. Retrieve the username for Grafana: `kubectl get secret grafana -n edge-observability -o jsonpath="{.data.admin-user}" | base64 --decode`
1. Retrieve the password for Grafana: `kubectl get secret grafana -n edge-observability -o jsonpath="{.data.admin-password}" | base64 --decode`
1. Open a web browser and navigate to `127.0.0.1:3000`. Enter the username and password retrieved from the previous steps to log in to Grafana and view the observability data. Check pre-built [Dashboards](https://grafana.com/docs/grafana/latest/dashboards/use-dashboards/) and use [Explore](https://grafana.com/docs/grafana/latest/explore/) functionality to view traces, logs and metrics.
