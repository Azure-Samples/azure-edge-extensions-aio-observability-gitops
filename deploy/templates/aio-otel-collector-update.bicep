param clusterName string
param customLocationName string = '${clusterName}-cl'
param location string = resourceGroup().location

var AIO_CLUSTER_RELEASE_NAMESPACE = 'azure-iot-operations'
var VERSIONS = {
  observability: '0.1.0-preview'
}
var observability_helmChart = {
  name: 'aio-observability'
  properties: {
    chart: {
      repo: 'mcr.microsoft.com/azureiotoperations/helm/aio-opentelemetry-collector'
      version: VERSIONS.observability
    }
    values: {
      config: {
        exporters: {
          prometheus: {
            endpoint: ':8889'
            resource_to_telemetry_conversion: {
              enabled: true
            }
          }
          prometheusremotewrite: {
            endpoint: 'http://prometheus-server.edge-observability/api/v1/write'
            resource_to_telemetry_conversion: {
              enabled: true
            }
          }
          'otlp/tempo': {
            endpoint: 'grafana-tempo.edge-observability:4317'
            tls: {
              insecure: true
            }
          }
          loki: {
            endpoint: 'http://grafana-loki.edge-observability:3100/loki/api/v1/push'
          }
        }
        extensions: {
          memory_ballast: {
            size_mib: 0
          }
        }
        processors: {
          memory_limiter: {
            check_interval: '60s'
            limit_percentage: 80
            spike_limit_percentage: 10
          }
        }
        receivers: {
          jaeger: null
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
          prometheus: null
          zipkin: null
        }

        service: {
          extensions: [
            'health_check'
          ]
          pipelines: {
            logs: {
              exporters: [
                'loki'
                'logging'
              ]
            }
            metrics: {
              receivers: [
                'otlp'
                'prometheus'
              ]
              exporters: [
                'prometheus'
                'prometheusremotewrite'
                'logging'
              ]
            }
            traces: {
              exporters: [
                'otlp/tempo'
                'logging'
              ]
            }
          }
          telemetry: null
        }
      }
      fullnameOverride: 'aio-otel-collector'
      mode: 'deployment'
      ports: {
        'jaeger-compact': {
          enabled: false
        }
        'jaeger-grpc': {
          enabled: false
        }
        'jaeger-thrift': {
          enabled: false
        }
        metrics: {
          enabled: true
          containerPort: 8889
          servicePort: 8889
          protocol: 'TCP'
        }
        zipkin: {
          enabled: false
        }
      }
      resources: {
        limits: {
          cpu: '100m'
          memory: '512Mi'
        }
      }
    }
  }
  type: 'helm.v3'
}

resource orchestrator_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' existing = {
  name: '${customLocationName}-aio-sync'
}

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
