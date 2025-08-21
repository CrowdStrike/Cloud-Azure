param identityPrincipalId string
param keyVaultName string
param roleDefinitionId string

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(identityPrincipalId, roleDefinitionId, keyVault.id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output keyVaultRoleAssignmentId string =  roleAssignment.id
