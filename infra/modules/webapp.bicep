@description('Location for the resource')
param location string

@description('Base name for resources')
param baseName string

@description('Environment name')
param environmentName string

@description('Tags to apply')
param tags object

@description('App Service Plan resource ID')
param appServicePlanId string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('ACR login server (e.g., myregistry.azurecr.io)')
param acrLoginServer string

@description('Azure AI Foundry endpoint URL')
param aiEndpoint string = ''

var appName = 'app-${baseName}-${environmentName}'

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  tags: union(tags, {
    'azd-service-name': 'web'
  })
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/zavastorefront:latest'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'AI__Endpoint'
          value: aiEndpoint
        }
      ]
    }
    httpsOnly: true
  }
}

output appName string = webApp.name
output principalId string = webApp.identity.principalId
output defaultHostName string = webApp.properties.defaultHostName
