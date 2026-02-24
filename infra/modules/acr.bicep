@description('Location for the resource')
param location string

@description('Base name for resources')
param baseName string

@description('Environment name')
param environmentName string

@description('Tags to apply')
param tags object

var acrName = replace('acr${baseName}${environmentName}', '-', '')

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output acrId string = acr.id
