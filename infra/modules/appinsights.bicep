@description('Location for the resource')
param location string

@description('Base name for resources')
param baseName string

@description('Environment name')
param environmentName string

@description('Tags to apply')
param tags object

var logAnalyticsName = 'log-${baseName}-${environmentName}'
var appInsightsName = 'appi-${baseName}-${environmentName}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

output connectionString string = appInsights.properties.ConnectionString
output instrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsName string = appInsights.name
