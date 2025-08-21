targetScope = 'subscription'
param canDelegate bool = false
param description string = 'Azure Automation RBAC permissions Required by PSFalcon and Azure Runbooks'
param principalId string
param roleId string
param scope string

resource rbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(scope, principalId, roleId)
  properties: {
    canDelegate: canDelegate
    description: description
    principalId: principalId
    roleDefinitionId:  resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: 'ServicePrincipal'
  }
}

output rbac string = rbac.properties.roleDefinitionId
