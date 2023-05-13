#!/usr/bin/env pwsh

function Get-OidcRequestToken()
{
    if (!$env:SYSTEM_ACCESSTOKEN) {
        throw "SYSTEM_ACCESSTOKEN not found"
    }
    return $env:SYSTEM_ACCESSTOKEN
}

function Get-OidcRequestUrl()
{
    $serviceConnectionId = Get-ServiceConnectionId
    if (!$serviceConnectionId) {
        throw "Unable to determine service connection ID"
    }
    $oidcRequestUrl = "${env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}${env:SYSTEM_TEAMPROJECTID}/_apis/distributedtask/hubs/build/plans/${env:SYSTEM_PLANID}/jobs/${env:SYSTEM_JOBID}/oidctoken?api-version=7.1-preview.1&serviceConnectionId=${serviceConnectionId}"
    Write-Verbose "OIDC Request URL: ${oidcRequestUrl}"
    return $oidcRequestUrl
}

function Get-ServiceConnectionId()
{
    # Get Service Connection ID
    Get-ChildItem -Path Env: -Recurse -Include ENDPOINT_DATA_* | Sort-Object -Property Name `
                                                               | Select-Object -First 1 -ExpandProperty Name `
                                                               | ForEach-Object { $_ -replace 'ENDPOINT_DATA_','' } `
                                                               | Set-Variable serviceConnectionId

    Write-Verbose "Service Connection ID: ${serviceConnectionId}"
    return $serviceConnectionId
}

function New-OidcToken()
{
    Write-Host "`nRequesting OIDC token from Azure DevOps..."
    Get-OidcRequestToken | Set-Variable oidcRequestToken
    Get-OidcRequestUrl | Set-Variable oidcRequestUrl
    Invoke-RestMethod -Headers @{
                        Authorization  = "Bearer ${oidcRequestToken}"
                        'Content-Type' = 'application/json'
                      } `
                      -Uri "${oidcRequestUrl}" `
                      -Method Post | Set-Variable oidcTokenResponse
    $oidcToken = $oidcTokenResponse.oidcToken
    if (!$oidcToken) {
        throw "Could not get OIDC token"
    }
    if ($oidcToken -notmatch "^ey") {
        throw "OIDC token in unexpected format"
    }
    return $oidcToken
}

if ($env:SYSTEM_DEBUG -eq "true") {
    $InformationPreference = "Continue"
    $VerbosePreference = "Continue"
    $DebugPreference = "Continue"
}

# Propagate Azure context to Terraform
az account show 2>$null | ConvertFrom-Json | Set-Variable account
if (!$account) {
    throw "Not logged into Azure CLI, no context to propagate as ARM_* environment variables"
}
if (![guid]::TryParse($account.user.name, [ref][guid]::Empty)) {
    throw "Azure CLI logged in with a User Principal instead of a Service Principal"
}
$env:ARM_CLIENT_ID       ??= $account.user.name
$env:ARM_CLIENT_SECRET   ??= $env:servicePrincipalKey # requires addSpnToEnvironment: true
$env:ARM_TENANT_ID       ??= $account.tenantId
$env:ARM_SUBSCRIPTION_ID ??= $account.id  

if ($env:ARM_CLIENT_SECRET) {
    Write-Verbose "Using ARM_CLIENT_SECRET"
} else {
    $env:ARM_OIDC_TOKEN  ??= New-OidcToken    
    Write-Verbose "Using ARM_OIDC_TOKEN"
}
Write-Host "Terraform azure provider environment variables:"
Get-ChildItem -Path Env: -Recurse -Include ARM_* | Select-Object -Property Name `
                                                 | Sort-Object -Property Name `
                                                 | Format-Table -HideTableHeader