#!/usr/bin/env pwsh

<# 
.SYNOPSIS 
    Updates image in classic (UI) pipeline definitions
 
.DESCRIPTION 
    This script is a wrapper around Terraform. It is provided for convenience only, as it works around some limitations in the demo. 
    E.g. terraform might need resources to be started before executing, and resources may not be accessible from the current locastion (IP address).

.EXAMPLE
    ./update_pipeline_image.ps1 -OrganizationUrl "https://dev.azure.com/myorg/" -Project "MyProject" -DeprecatedImage vs2017-win2016 -ReplaceWithImage windows-2019
#> 
#Requires -Version 7
param ( 
    [parameter(Mandatory=$false)][string]$DeprecatedImage="vs2017-win2016",
    [parameter(Mandatory=$true)][string]$OrganizationUrl,
    [parameter(Mandatory=$true)][string]$Project,
    [parameter(Mandatory=$false)][string]$ReplaceWithImage="windows-2019",
    [parameter(Mandatory=$false)][string]$Token=$env:AZURE_DEVOPS_EXT_PAT ?? $env:SYSTEM_ACCESSTOKEN
) 

function BuildHeaders(
    [parameter(Mandatory=$true)][string]$Token
)
{
    $base64AuthInfo = [Convert]::ToBase64String([System.Text.ASCIIEncoding]::ASCII.GetBytes(":${Token}"))
    $authHeader = "Basic $base64AuthInfo"
    Write-Debug "Authorization: $authHeader"
    $requestHeaders = @{
        Accept = "application/json"
        Authorization = $authHeader
        "Content-Type" = "application/json"
    }

    return $requestHeaders
}

function Get-DeprecatedPipelines(
    [parameter(Mandatory=$true)][string]$DeprecatedImage,
    [parameter(Mandatory=$true)][string]$OrganizationUrl,
    [parameter(Mandatory=$true)][string]$Project,
    [parameter(Mandatory=$true)][string]$Token
)
{
    # az devops cli does not (yet) allow updates, so using the REST API
    $apiVersion="6.0"

    $listApi = "${OrganizationUrl}/${Project}/_apis/build/definitions?api-version=${apiVersion}&includeAllProperties=true"
    Write-Debug "REST API Url: $listApi"

    # Retrieve pipeline
    $requestHeaders = BuildHeaders -Token $Token
    Invoke-RestMethod -Headers $requestHeaders -Method 'Get' -Uri $listApi | Set-Variable pipelines
    $pipelines.value | Write-Verbose
    $pipelines.value | Where-Object {$_.process.target.agentSpecification.identifier -eq $DeprecatedImage} | Set-Variable deprecatedPipelines

    return $deprecatedPipelines
}

function Update-Pipeline(
    [parameter(Mandatory=$true)][int]$DefinitionId,
    [parameter(Mandatory=$true)][string]$DeprecatedImage,
    [parameter(Mandatory=$true)][string]$OrganizationUrl,
    [parameter(Mandatory=$true)][string]$Project,
    [parameter(Mandatory=$true)][string]$ReplaceWithImage,
    [parameter(Mandatory=$true)][string]$Token
)
{
    # az devops cli does not (yet) allow updates, so using the REST API
    $OrganizationUrl = $OrganizationUrl -replace "/$","" # Strip trailing '/'
    $apiVersion="6.0"

    $itemApi = "${OrganizationUrl}/${Project}/_apis/build/definitions/${DefinitionId}?api-version=${apiVersion}"
    Write-Debug "REST API Url: $itemApi"

    # Retrieve pipeline
    $requestHeaders = BuildHeaders -Token $Token
    Invoke-RestMethod -Headers $requestHeaders -Method 'Get' -Uri $itemApi | Set-Variable pipelineSettings
    $pipelineSettings | ConvertTo-Json -Depth 10 | Write-Debug
    
    # Test whether update is needed
    if (!$pipelineSettings.queue.pool.isHosted) {
        Write-Host "Not a Microsoft-hosted pipeline, skipping"
        return
    }
    $vmImage = $pipelineSettings.process.target.agentSpecification.identifier
    if (!$vmImage) {
        Write-Host "Image not defined, not a classic / UI pipeline"
        return
    }
    Write-Host "Pipeline $DefinitionId is using '$vmImage'"

    # Update pipeline
    if ($vmImage -eq $DeprecatedImage) {
        Write-Host "Updating pipeline $DefinitionId to '$ReplaceWithImage'..."
        $pipelineSettings.process.target.agentSpecification.identifier = $ReplaceWithImage
        $pipelineSettings | ConvertTo-Json -Depth 7 | Invoke-RestMethod -Headers $requestHeaders -Method 'Put' -Uri $itemApi | Set-Variable pipelineSettings
        Write-Host "Pipeline $DefinitionId updated to '$($pipelineSettings.process.target.agentSpecification.identifier)'"
    }
}

$OrganizationUrl = $OrganizationUrl -replace "/$","" # Strip trailing '/'

"Retrieving classic / UI pipelines using '{0}' in {1}/{2}" -f $DeprecatedImage, $OrganizationUrl, $Project | Write-Host
Get-DeprecatedPipelines -DeprecatedImage $DeprecatedImage `
                        -OrganizationUrl $OrganizationUrl -Project $Project `
                        -Token $Token `
                        | Set-Variable deprecatedPipelines

if (!$deprecatedPipelines) {
    "No classic / UI pipelines found using '{0}' in {1}/{2}" -f $DeprecatedImage, $OrganizationUrl, $Project | Write-Host
    exit
}
                        
foreach ($pipeline in $deprecatedPipelines) {
    "Updating pipeline '{0}' ({1}) {2} -> {3}..." -f $pipeline.name, $pipeline.id, $DeprecatedImage, $ReplaceWithImage | Write-Host
    Update-Pipeline -DefinitionId $pipeline.id `
                    -DeprecatedImage $DeprecatedImage `
                    -OrganizationUrl $OrganizationUrl -Project $Project `
                    -ReplaceWithImage $ReplaceWithImage `
                    -Token $Token

}