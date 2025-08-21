

param keyVaultName string
param location string = resourceGroup().location
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'
param spName string
@secure()
param spPassword string
param falconClientId string
@secure()
param falconClientSecret string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
  }
    publicNetworkAccess: 'Enabled'
  }
}

resource servicePrincipalName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'app-id'
  properties: {
    value: spName
  }
}

resource servicePrincipalPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'app-secret'
  properties: {
    value: spPassword
  }
}

resource clientId 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'falcon-client-id'
  properties: {
    value: falconClientId
  }
}

resource clientSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'falcon-client-secret'
  properties: {
    value: falconClientSecret
  }
}

output keyVaultName string = keyVault.name
output keyVaultResourceId string = keyVault.id
