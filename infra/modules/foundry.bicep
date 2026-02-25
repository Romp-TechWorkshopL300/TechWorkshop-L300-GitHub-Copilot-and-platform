@description('Location for the resource')
param location string

@description('Base name for resources')
param baseName string

@description('Environment name')
param environmentName string

@description('Tags to apply')
param tags object

var accountName = 'foundry-${baseName}-${environmentName}'

resource cognitiveAccount 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: accountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: cognitiveAccount
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: cognitiveAccount
  name: 'phi-4-mini-instruct'
  dependsOn: [gpt4oDeployment]
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4-mini-instruct'
      version: '1'
    }
  }
}

output accountName string = cognitiveAccount.name
output endpoint string = cognitiveAccount.properties.endpoint
