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

var appName = 'app-${baseName}-${environmentName}'

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  tags: union(tags, {
    'azd-service-name': 'web'
  })
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
    httpsOnly: true
  }
}

output appName string = webApp.name
output principalId string = webApp.identity.principalId
output defaultHostName string = webApp.properties.defaultHostName
