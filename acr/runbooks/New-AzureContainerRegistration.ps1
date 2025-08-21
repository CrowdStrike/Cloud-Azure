    <#
    .SYNOPSIS
    Creates a new Azure container registration.

    .DESCRIPTION
    This script on-boards an Azure container registratry to the Falcon Cloud Security Platform.

    .PARAMETER ClientId
    The client ID of the Falcon Cloud Security platform.

    .PARAMETER ClientSecret
    The client secret of the Falcon Cloud Security platform.

    .PARAMETER MemberCid
    The member MemberCID of the Falcon Cloud Security platform.

    .PARAMETER Cloud
    The cloud environment for the Falcon Cloud Security platform. Valid values are 'us-1', 'us-2', 'us-gov-1', and 'eu-1'.

    .PARAMETER Environment
    The environment for the Azure container registration.

    .PARAMETER SubscriptionId
    The subscription ID of the Azure subscription.

    .PARAMETER TenantId
    The tenant ID of the Azure Active Directory (AAD) tenant.

    .PARAMETER ServicePrincipalPw
    The password for the service principal.

    .PARAMETER ApplicationId
    The application ID of the Azure Active Directory (AAD) application.
    #>

#Requires -Version 5.1
using module @{ModuleName = 'PSFalcon'; ModuleVersion = '2.2' }
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 6)]
    [string]$Environment,

    [Parameter(Mandatory, Position = 7)]
    [string]$SubscriptionId,

    [Parameter(Mandatory, Position = 8)]
    [string]$TenantId,

    [Parameter(Mandatory, Position = 11)]
    [string]$VaultName
)
try
{
    # Authenticate to Azure using system assigned managed identity on Automation Account
    $AzureContext =  (Connect-AzAccount -Identity).context
    $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
    Write-Output $AzureContext
}
catch 
{
    Write-Output "Authentication to Azure failed. Aborting.";
    throw $_
}
try 
{
    # Retrieve secrets from Azure Key Vault
    $clientId = (Get-AzKeyVaultSecret -VaultName $VaultName -Name falcon-client-id -AsPlainText)
    $clientSecret = (Get-AzKeyVaultSecret -VaultName $VaultName -Name falcon-client-secret -AsPlainText)
    $appId = (Get-AzKeyVaultSecret -VaultName $VaultName -Name app-id -AsPlainText)
    $appSecret = (Get-AzKeyVaultSecret -VaultName $VaultName -Name app-secret -AsPlainText)

    # Authenticate to Falcon Cloud Security
    $Token = @{
    ClientId=$clientId
    ClientSecret=$clientSecret
    }

    Request-FalconToken @Token
    if ((Test-FalconToken).Token -eq $true) 
    {
        # Get Azure Container Registry in Subscription
        $azureContainerRegistry = Get-AzContainerRegistry
        
        # Get Connected Falcon Container Registry in Falcon Cloud Security
        $falconRegistryConnections = Get-FalconContainerRegistry 
        $currentRegistry = @()

        # Retrieve value from Key Vault
        foreach ($id in $falconRegistryConnections)
        {
            $acrName = (Get-FalconContainerRegistry -id $id).user_defined_alias
            $currentRegistry += ($acrName)
            Write-Output "Registry Connection in Falcon Cloud Security: $acrName"
        }
        # Connect Azure Container Registry to Falcon Cloud Security if not already connected
        foreach ($registry in $azureContainerRegistry)
        {
            $null = $credentials 
            $credentials = @{
                "username" = $appId
                "password" = $appSecret
            }
            if($credentials)
            {
                $loginServer = 'https://' + $registry.LoginServer
                if($currentRegistry -notcontains $registry.name)
                {
                    Write-Output "Unconnected registry found: $($registry.name)!"
                    New-FalconContainerRegistry -Name $registry.Name -Type acr -Credential $credentials -Verbose -Url $loginServer 
                    Write-Output "Connected $($registry.name) to Falcon Cloud Security"
                }
                else 
                {
                    Write-OUtput "Registry $($registry.name) is already connected to Falcon Cloud Security skipping"
                }
            }
        }
    }
}
catch 
{
    throw $_
}
finally 
{
    if ((Test-FalconToken).Token -eq $true) { Revoke-FalconToken }
}
