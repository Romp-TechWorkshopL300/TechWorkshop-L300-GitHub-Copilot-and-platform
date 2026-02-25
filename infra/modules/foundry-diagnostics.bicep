@description('Name of the Cognitive Services account')
param accountName string

@description('Resource ID of the Log Analytics workspace')
param logAnalyticsWorkspaceId string

resource cognitiveAccount 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' existing = {
  name: accountName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'foundry-diagnostics'
  scope: cognitiveAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Audit'
        enabled: true
      }
      {
        category: 'RequestResponse'
        enabled: true
      }
      {
        category: 'AzureOpenAIRequestUsage'
        enabled: true
      }
      {
        category: 'Trace'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
