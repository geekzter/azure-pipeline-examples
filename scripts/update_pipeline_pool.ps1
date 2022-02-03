#!/usr/bin/env pwsh

#Requires -Version 7

function UpdatePipeline(
    [parameter(Mandatory=$true)][int]$DefinitionId,
    # [parameter(Mandatory=$true)][int]$AgentPoolId,
    [parameter(Mandatory=$true)][string]$OrganizationUrl,
    [parameter(Mandatory=$true)][string]$Project,
    [parameter(Mandatory=$false)][hashtable]$Settings,
    [parameter(Mandatory=$true)][string]$Token=$env:AZURE_DEVOPS_EXT_PAT ?? $env:SYSTEM_ACCESSTOKEN
)
{
    # az devops cli does not (yet) allow updates, so using the REST API
    $OrganizationUrl = $OrganizationUrl -replace "/$","" # Strip trailing '/'
    $apiVersion="6.0"
    # $apiVersion="6.1-preview.7"

    # URL template: https://dev.azure.com/{organization}/{project}/_apis/build/definitions/{definitionId}?api-version=6.1-preview.7
    $apiUrl = "${OrganizationUrl}/${Project}/_apis/build/definitions/${DefinitionId}?api-version=${apiVersion}"
    Write-Debug "REST API Url: $apiUrl"

    # Prepare REST request
    $base64AuthInfo = [Convert]::ToBase64String([System.Text.ASCIIEncoding]::ASCII.GetBytes(":${Token}"))
    $authHeader = "Basic $base64AuthInfo"
    Write-Debug "Authorization: $authHeader"
    $requestHeaders = @{
        Accept = "application/json"
        Authorization = $authHeader
        "Content-Type" = "application/json"
    }

# {
#     "id": 882,
#     "name": "Azure Pipelines",
#     "pool": {
#         "id": 17,
#         "name": "Azure Pipelines",
#         "isHosted": true
#     }
# }

    # $Settings["id"] = $DefinitionId
    # $requestBody = $Settings | ConvertTo-Json
    # Write-Verbose "`$requestBody: $requestBody"
    if ($DebugPreference -ine "SilentlyContinue") {
        Invoke-WebRequest -Uri $apiUrl -Headers $requestHeaders -Body $requestBody -Method Get | Set-Variable pipeline
        $pipeline.Content | jq
    }

    # $updateResponse = Invoke-WebRequest -Uri $apiUrl -Headers $requestHeaders -Body $requestBody -Method Patch
    # Write-Information "Response status: $($updateResponse.StatusDescription)"
    # Write-Debug $updateResponse | Out-String
    # $updateResponseContent = $updateResponse.Content | ConvertFrom-Json
    # Write-Debug $updateResponseContent | Out-String

    return $updateResponseContent
}

UpdatePipeline -OrganizationUrl "https://dev.azure.com/ericvan/" -Project "Pipeline%20Samples" `
               -Token $env:AZURE_DEVOPS_EXT_PAT `
               -DefinitionId 126