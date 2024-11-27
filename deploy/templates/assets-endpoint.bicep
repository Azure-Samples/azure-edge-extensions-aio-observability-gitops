param clusterName string
param customLocationName string
param location string = resourceGroup().location
param opcuaEndpoint string = 'opc.tcp://opcplc-000000:50000'

resource cluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: clusterName
}

resource deviceRegistry_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' existing = {
  scope: cluster
  name: 'assets'
}

resource opc_ua_connector_0 'microsoft.deviceregistry/assetendpointprofiles@2024-11-01' = {
  extendedLocation: {
    name: resourceId(
      'Microsoft.ExtendedLocation/customLocations',
      customLocationName
    )
    type: 'CustomLocation'
  }
  location: location
  name: 'opc-ua-connector-0'
  properties: {
    targetAddress: opcuaEndpoint
    endpointProfileType: 'OpcUa'
    authentication: {
      method: 'Anonymous'
    }
    additionalConfiguration: '{"applicationName": "opc-ua-connector-0", "security": { "autoAcceptUntrustedServerCertificates": true}}'
  }
  dependsOn: [
    deviceRegistry_extension
  ]
}

resource thermostat 'microsoft.deviceregistry/assets@2024-11-01' = {
  extendedLocation: {
    name: resourceId(
      'Microsoft.ExtendedLocation/customLocations',
      customLocationName
    )
    type: 'CustomLocation'
  }
  location: location
  name: 'thermostat'
  properties: {
    assetEndpointProfileRef: 'opc-ua-connector-0'
    defaultDatasetsConfiguration: '{"publishingInterval":1000,"samplingInterval":1000,"queueSize":1}'
    datasets: [
      {
        name: 'default'
        dataPoints: [
          {
            name: 'temperature'
            dataSource: 'nsu=http://microsoft.com/Opc/OpcPlc/;s=FastUInt1'
            observabilityMode: 'Log'
            dataPointConfiguration: '{}'
          }
          {
            name: 'vibration'
            dataSource: 'nsu=http://microsoft.com/Opc/OpcPlc/;s=FastUInt2'
            observabilityMode: 'None'
            dataPointConfiguration: '{}'
          }
        ]
      }
    ]
    defaultEventsConfiguration: '{"publishingInterval": 1000, "samplingInterval": 500, "queueSize": 1}'
    description: 'A simulated thermostat asset'
    displayName: 'thermostat'
    enabled: true
    events: []
    manufacturer: 'Contoso'
  }
  dependsOn: [
    opc_ua_connector_0
  ]
}
