# Sample with Azure IoT Operations Preview and Local Observability with OpenTelemetry and GitOps

This sample is currently work in progress.

In this sample, a Visual Studio Code dev container is used as the developer sandbox to leverage a local K3D cluster, initialize Azure resources and install a baseline set of Azure IoT Operations' components.

The objective is to illustrate how to setup observability to be able to locally vizualize health of the cluster and Azure IoT Operations' components. This repository is particularly useful for those interested in edge-based visualization. More details about the setup can be found [here](./docs/observability-setup.md).

If you’re looking for a default observability setup and wish to analyze observability data using Azure Monitor, follow [this documentation](https://learn.microsoft.com/en-us/azure/iot-operations/monitor/howto-configure-observability).


> [!WARNING]
Azure IoT Operations is still in Preview. Any parts of sample could stop working as the product evolves towards General Availability.

<!-- ## Features (TODO to come later)

This project framework provides the following features:

* Feature 1
* Feature 2
* ... -->

## Getting Started

### Prerequisites

* Visual Studio Code
* Dev Containers support in Visual Studio Code
* Azure subscription
* Azure account with Owner permissions on the Subscription
* Docker runtime

### Installation

We recommend you fork this project in GitHub and clone the fork in order to setup GitOps independently from the main repo. This will enable you to apply changes and experiment more easily.

By using the Dev Container, a K3D cluster and any documented client tools will be automatically installed and ready to use for testing out the sample.

* Fork this repository in GitHub.
* Clone your fork locally.
* Open the project with Visual Studio Code.
* Launch the Dev Container with Command Palette > `Dev Containers: Reopen in Container`. First time building the container may take a while.
* Open a `bash` terminal and leave the current directory to the default root folder `/workspaces/azure-edge-extensions-aio-observability-gitops`.
* Log into Azure and set your default subscription.

  ```bash
  az login --tenant <your tenant ID or domain>

  az account set -s <your subscription ID or name>`
  ```

* Run the following in the `bash` terminal to create a file in the `./temp` directory for storing and loading environment variables. This folder is excluded from Git.

```bash
if [ ! -d "./temp" ]; then
    mkdir ./temp
fi
>./temp/envvars.sh cat <<EOF
# change the below set to match your environment based on Readme
export RESOURCE_GROUP=YOUR_CHOICE # For example rg-myabbrev-dev1
export CLUSTER_NAME=YOUR_CHOICE # For example arck-myabbrev-dev1
export AKV_NAME=YOUR_CHOICE # For example arck-myabbrev-dev1
export LOCATION=northeurope # replace by your choice based on available regions, see Readme
export ARC_CUSTOMLOCATION_OID="" # see Readme
export DEFAULT_NAMESPACE=azure-iot-operations # do not change
export GITOPS_SOURCE_REPO="https://github.com/Azure-Samples/azure-edge-extensions-aio-observability-gitops" # change to your repo fork if you are testing your own version
export GITOPS_BRANCH="main" # change if desired
EOF

code ./temp/envvars.sh

```

* The newly created file `./temp/envvars.sh` should now be open in the Code editor.
* Update the variables in the file according to these details:
  * For the resource names, use your preferred Azure resource names in the variable contents. An example using the recommended resource abbreviations provided in the comments
  * `ARC_CUSTOMLOCATION_OID`: retrieve the unique Custom location Object ID for your tenant by running `az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv`
  * `LOCATION`: make sure you choose something from the supported list of regions as documented in [Deploy Azure IoT Operations, see Location table](https://learn.microsoft.com/en-us/azure/iot-operations/get-started/quickstart-deploy?tabs=codespaces#connect-a-kubernetes-cluster-to-azure-arc)

* Load the environment variables in your terminal by running:

  ```bash
  source ./temp/envvars.sh
  ```

### Quickstart

Enable the local K3D cluster to Azure Arc and install Azure IoT Operations with the default components and configuration.

1. In a `bash` terminal, run the script script `./deploy/1-arc-k8s-connect.sh` to connect the K3D cluster to Azure Arc. This will take a few minutes.
1. Run the script `./deploy/2-azure-iot-operations.sh`. Grab a coffee, this can take 15 minutes.
1. Validate the installation finished correctly by running `mqttui` in the terminal. You should see messages being published in the topic `azure-iot-operations`.
1. Run the script `./deploy/3-flux-install.sh` to create a [Flux](https://fluxcd.io/flux/) configuration.
1. Run the script `./deploy/4-otel-collector-update.sh` to update aio-otel-collector to export observability data to local edge observability components.

### View observability data

Through Flux a set of components for local edge observability was deployed to the cluster. It includes Grafana for interactive visualizations and analytics, Tempo for tracing, Loki for logging, and Prometheus for metrics.

To view the observability data, follow these steps:

1. Initiate port forwarding with the following command: `kubectl port-forward svc/grafana 3000:80 -n edge-observability`
1. Retrieve the username for Grafana: `kubectl get secret grafana -n edge-observability -o jsonpath="{.data.admin-user}" | base64 --decode`
1. Retrieve the password for Grafana: `kubectl get secret grafana -n edge-observability -o jsonpath="{.data.admin-password}" | base64 --decode`
1. Open a web browser and navigate to `127.0.0.1:3000`. Enter the username and password retrieved from the previous steps to log in to Grafana and view the observability data. Check pre-built [Dashboards](https://grafana.com/docs/grafana/latest/dashboards/use-dashboards/) and use [Explore](https://grafana.com/docs/grafana/latest/explore/) functionality to view traces, logs and metrics.

<!-- ## Demo (TODO)

A demo app is included to show how to use the project.

To run the demo, follow these steps:

(Add steps to start up the demo)

1.
2.
3. -->

<!-- 
## Resources (TODO)

(Any additional resources or related projects)

- Link to supporting information
- Link to similar sample
- ... -->
