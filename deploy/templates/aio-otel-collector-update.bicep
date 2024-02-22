param clusterName string
param customLocationName string = '${clusterName}-cl'
param location string = resourceGroup().location

var AIO_CLUSTER_RELEASE_NAMESPACE = 'azure-iot-operations'
var VERSIONS = {
  observability: '0.1.0-preview'
}

resource orchestrator_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' existing = {
  name: '${customLocationName}-aio-sync'
}

// Load the base helm chart config and the overlay helm chart config.
// Apply the overlay config over the base config using union().
var baseValues = loadYamlContent('aio-otel-collector-base-values.yml')
var overlayValues = loadYamlContent('aio-otel-collector-overlay-values.yml')
var aioObservabilityValues = union(baseValues, overlayValues)

resource target 'Microsoft.IoTOperationsOrchestrator/targets@2023-10-04-preview' = {
  name: 'aio-otel-collector-override'
  location: location
  extendedLocation: {
    name: resourceId(
      'Microsoft.ExtendedLocation/customLocations',
      customLocationName
    )
    type: 'CustomLocation'
  }
  properties: {
    scope: AIO_CLUSTER_RELEASE_NAMESPACE
    components: [
      {
        name: 'aio-observability'
        type: 'helm.v3'
        properties: {
          chart: {
            repo: 'mcr.microsoft.com/azureiotoperations/helm/aio-opentelemetry-collector'
            version: VERSIONS.observability
          }
          values: aioObservabilityValues
        }
      }
    ]
    topologies: [
      {
        bindings: [
          {
            config: {
              inCluster: 'true'
            }
            provider: 'providers.target.helm'
            role: 'helm.v3'
          }
          {
            config: {
              inCluster: 'true'
            }
            provider: 'providers.target.kubectl'
            role: 'yaml.k8s'
          }
        ]
      }
    ]
    version: deployment().properties.template.contentVersion
  }
  dependsOn: [
    orchestrator_syncRule
  ]
}
