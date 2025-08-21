param automationAccountName string
param environment string
param keyVaultName string
param location string
param now string = utcNow('yyyy-MM-ddTHH:mm:ss')
param psFalconUri string
param psFalconVersion string
param runbookNames array
param subscriptionId string
param tenantId string
param todayDate string = utcNow('yyyy-MM-dd')

var nowTicks = dateTimeToEpoch(now)
var offsetSeconds = 300 // time delay of 5min to allow for deployment delays
var startTime = '01:00:00'

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: automationAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
      identity: {}
    }
  }
}

resource aa 'Microsoft.Automation/automationAccounts@2021-06-22' existing = {
  name: automationAccount.name
}

resource runbookDeployment 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = [for (runbook, i) in runbookNames: {
  name: runbook.name
  parent: aa
  location: location
  properties: {
    runbookType: 'PowerShell'
    logProgress: true
    logVerbose: true
    publishContentLink: {
      uri: runbook.uri
      version: '1.0.0.0'
    }
  }
}]

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  name: 'runbookSchedule'
  parent: aa
  properties: {
    description: 'Schedule for the PSFalcon runbook to connect new ACR to Falcon Cloud Security'
    expiryTime: '9999-12-31T00:00:00Z'
    frequency: 'Hour'
    interval: 1
    startTime: dateTimeAdd('${todayDate}T${startTime}', dateTimeToEpoch('${todayDate}T${startTime}') > nowTicks + offsetSeconds ? 'P0D' : 'P1D')
    timeZone: 'Eastern Standard Time'
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
  #disable-next-line use-stable-resource-identifiers
  name: guid(now)
  parent: aa
  properties:{
    parameters: {
      environment: environment
      vaultName: keyVaultName
      subscriptionId: subscriptionId
      tenantId: tenantId
    }
    schedule: {
      name: schedule.name
      }
    runbook: {
      name: runbookNames[0].name
      }
  }
  dependsOn: [
    runbookDeployment
  ]
}

resource psFaclonModule 'Microsoft.Automation/automationAccounts/modules@2022-08-08' = {
  name: 'PSFalcon'
  location: location
  parent: aa
  properties: {
    contentLink: {
      uri: psFalconUri
      version: psFalconVersion
    }
  }
}

output aaIdentityId string = aa.identity.principalId
