targetScope = 'subscription'

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('Primary location for all resources')
param location string = 'westus3'

@description('Base name for resources')
param baseName string = 'zavastore'

var resourceGroupName = 'rg-${baseName}-${environmentName}-${location}'
var tags = {
  environment: environmentName
  application: baseName
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  scope: rg
  params: {
    location: location
    baseName: baseName
    environmentName: environmentName
    tags: tags
  }
}

module appInsights 'modules/appinsights.bicep' = {
  name: 'appinsights-deployment'
  scope: rg
  params: {
    location: location
    baseName: baseName
    environmentName: environmentName
    tags: tags
  }
}

module appServicePlan 'modules/appserviceplan.bicep' = {
  name: 'appserviceplan-deployment'
  scope: rg
  params: {
    location: location
    baseName: baseName
    environmentName: environmentName
    tags: tags
  }
}

module webApp 'modules/webapp.bicep' = {
  name: 'webapp-deployment'
  scope: rg
  params: {
    location: location
    baseName: baseName
    environmentName: environmentName
    tags: tags
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    appInsightsConnectionString: appInsights.outputs.connectionString
    acrLoginServer: acr.outputs.acrLoginServer
  }
}

module acrPullRole 'modules/roleassignment.bicep' = {
  name: 'acr-pull-role-deployment'
  scope: rg
  params: {
    principalId: webApp.outputs.principalId
    acrName: acr.outputs.acrName
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundry-deployment'
  scope: rg
  params: {
    location: location
    baseName: baseName
    environmentName: environmentName
    tags: tags
  }
}

module foundryRole 'modules/foundry-roleassignment.bicep' = {
  name: 'foundry-role-deployment'
  scope: rg
  params: {
    principalId: webApp.outputs.principalId
    accountName: foundry.outputs.accountName
  }
}

module foundryDiagnostics 'modules/foundry-diagnostics.bicep' = {
  name: 'foundry-diagnostics-deployment'
  scope: rg
  params: {
    accountName: foundry.outputs.accountName
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
  }
}

output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.acrName
output AZURE_CONTAINER_REGISTRY_LOGIN_SERVER string = acr.outputs.acrLoginServer
output AZURE_APP_SERVICE_NAME string = webApp.outputs.appName
output AZURE_APP_INSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
