param clusterName string
param customLocationName string = '${clusterName}-cl'
param location string = resourceGroup().location
param opcuaEndpoint string = 'opc.tcp://opcplc-000000:50000'

resource cluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: clusterName
}

resource deviceRegistry_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' existing = {
  scope: cluster
  name: 'assets'
}

resource opc_ua_connector_0 'microsoft.deviceregistry/assetendpointprofiles@2023-11-01-preview' = {
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
    transportAuthentication: {
      ownCertificates: []
    }
    userAuthentication: {
      mode: 'Anonymous'
    }
    additionalConfiguration: '{"applicationName": "opc-ua-connector", "security": { "autoAcceptUntrustedServerCertificates": true}}'
  }
  dependsOn: [
    deviceRegistry_extension
  ]
}

resource thermostat 'microsoft.deviceregistry/assets@2023-11-01-preview' = {
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
    assetEndpointProfileUri: 'opc-ua-connector-0'
    dataPoints: [
      {
        capabilityId: 'temperature,'
        dataPointConfiguration: '{}'
        dataSource: 'nsu=http://microsoft.com/Opc/OpcPlc/;s=FastUInt1,'
        name: 'temperature,'
        observabilityMode: 'log'
      }
      {
        dataPointConfiguration: '{}'
        dataSource: 'nsu=http://microsoft.com/Opc/OpcPlc/;s=FastUInt2'
        observabilityMode: 'none'
      }
    ]
    defaultDataPointsConfiguration: '{"publishingInterval": "2000", "samplingInterval": "1000", "queueSize": "1"}'
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
