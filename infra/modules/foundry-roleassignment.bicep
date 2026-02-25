@description('Principal ID of the Web App managed identity')
param principalId string

@description('Name of the Cognitive Services account')
param accountName string

// Cognitive Services User built-in role definition ID
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'

resource cognitiveAccount 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' existing = {
  name: accountName
}

resource cognitiveServicesRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cognitiveAccount.id, principalId, cognitiveServicesUserRoleId)
  scope: cognitiveAccount
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
    principalType: 'ServicePrincipal'
  }
}
