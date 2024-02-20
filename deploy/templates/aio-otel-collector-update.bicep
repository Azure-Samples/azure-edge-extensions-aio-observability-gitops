param clusterName string
param customLocationName string = '${clusterName}-cl'
param location string = resourceGroup().location
param targetName string = '${toLower(clusterName)}-target'

var AIO_CLUSTER_RELEASE_NAMESPACE = 'azure-iot-operations'
var VERSIONS = {
  observability: '0.1.0-preview'
}
var observability_helmChart = {
  name: 'aio-observability'
  type: 'helm.v3'
  properties: {
    chart: {
      repo: 'mcr.microsoft.com/azureiotoperations/helm/aio-opentelemetry-collector'
      version: VERSIONS.observability
    }
    values: {
      mode: 'deployment'
      fullnameOverride: 'aio-otel-collector'
      config: {
        processors: {
          memory_limiter: {
            limit_percentage: 80
            spike_limit_percentage: 10
            check_interval: '60s'
          }
        }
        receivers: {
          jaeger: null
          prometheus: null
          zipkin: null
          otlp: {
            protocols: {
              grpc: {
                endpoint: ':4317'
              }
              http: {
                endpoint: ':4318'
              }
            }
          }
        }
        exporters: {
          prometheus: {
            endpoint: ':8889'
            resource_to_telemetry_conversion: {
              enabled: true
            }
          }
        }
        service: {
          extensions: [
            'health_check'
          ]
          pipelines: {
            metrics: {
              receivers: [
                'otlp'
              ]
              exporters: [
                'prometheus'
              ]
            }
            logs: null
            traces: null
          }
          telemetry: null
        }
        extensions: {
          memory_ballast: {
            size_mib: 0
          }
        }
      }
      resources: {
        limits: {
          cpu: '100m'
          memory: '512Mi'
        }
      }
      ports: {
        metrics: {
          enabled: true
          containerPort: 8889
          servicePort: 8889
          protocol: 'TCP'
        }
        'jaeger-compact': {
          enabled: false
        }
        'jaeger-grpc': {
          enabled: false
        }
        'jaeger-thrift': {
          enabled: false
        }
        zipkin: {
          enabled: false
        }
      }
    }
  }
}

resource orchestrator_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' existing = {
  name: '${customLocationName}-aio-sync'
}

resource target 'Microsoft.IoTOperationsOrchestrator/targets@2023-10-04-preview' = {
  extendedLocation: {
    name: resourceId(
      'Microsoft.ExtendedLocation/customLocations',
      customLocationName
    )
    type: 'CustomLocation'
  }
  location: location
  name: targetName
  properties: {
    components: [observability_helmChart]
    scope: AIO_CLUSTER_RELEASE_NAMESPACE
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

output targetName string = targetName
