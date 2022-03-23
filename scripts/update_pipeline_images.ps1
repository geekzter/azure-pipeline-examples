#!/usr/bin/env pwsh

<# 
.SYNOPSIS 
    Updates image in classic (UI) pipeline definitions in a given project
 
.DESCRIPTION 
    This script is a wrapper around Terraform. It is provided for convenience only, as it works around some limitations in the demo. 
    E.g. terraform might need resources to be started before executing, and resources may not be accessible from the current locastion (IP address).

.EXAMPLE
    ./update_pipeline_images.ps1 -OrganizationUrl "https://dev.azure.com/myorg/" -Project "MyProject" -DeprecatedImage vs2017-win2016 -ReplaceWithImage windows-2019
#> 
#Requires -Version 7
param ( 
    [parameter(Mandatory=$false)][string]$DeprecatedImage="vs2017-win2016",
    [parameter(Mandatory=$false)][int]$MaxItems=200,
    [parameter(Mandatory=$true)][string]$OrganizationUrl,
    [parameter(Mandatory=$false)][string]$Project,
    [parameter(Mandatory=$false)][string]$ReplaceWithImage="windows-2019",
    [parameter(Mandatory=$false)][string]$Token=$env:AZURE_DEVOPS_EXT_PAT
) 
$apiVersion="6.0"

function Build-Headers(
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

function Find-Pipelines(
    [parameter(Mandatory=$true)][string]$DeprecatedImage,
    [parameter(Mandatory=$true)][string]$OrganizationUrl,
    [parameter(Mandatory=$true)][string]$Project,
    [parameter(Mandatory=$true)][string]$Token
)
{
    $listApi = "${OrganizationUrl}/${Project}/_apis/build/definitions?api-version=${apiVersion}&includeAllProperties=true&`$top=${MaxItems}"
    Write-Debug "REST API Url: $listApi"

    # Retrieve pipeline
    $requestHeaders = Build-Headers -Token $Token
    Invoke-RestMethod -Headers $requestHeaders -Method 'Get' -Uri $listApi | Set-Variable pipelines
    # Filter pipelines with either pipeline image or at least one job level image matching the given deprecated image name
    $pipelines.value | Where-Object {
        ($_.process.target.agentSpecification.identifier -eq $DeprecatedImage) -or `
        ($_.process.phases.target.agentSpecification.identifier -contains $DeprecatedImage)
    } | Set-Variable pipelinedUsingDeprecatedImages

    return $pipelinedUsingDeprecatedImages
}

function List-Projects(
    [parameter(Mandatory=$true)][string]$OrganizationUrl,
    [parameter(Mandatory=$true)][string]$Token
)
{
    $listApi = "${OrganizationUrl}/_apis/projects?api-version=${apiVersion}&stateFilter=wellFormed&`$top=${MaxItems}"
    Write-Debug "REST API Url: $listApi"

    # Retrieve pipeline
    $requestHeaders = Build-Headers -Token $Token
    Invoke-RestMethod -Headers $requestHeaders -Method 'Get' -Uri $listApi | Set-Variable projects

    return $projects
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
    
    $itemApi = "${OrganizationUrl}/${Project}/_apis/build/definitions/${DefinitionId}?api-version=${apiVersion}"
    Write-Debug "REST API Url: $itemApi"

    # Retrieve pipeline
    $requestHeaders = Build-Headers -Token $Token
    Invoke-RestMethod -Headers $requestHeaders -Method 'Get' -Uri $itemApi | Set-Variable pipelineSettings
    $pipelineSettings | ConvertTo-Json -Depth 10 | Write-Debug
    
    # Test whether update is needed
    if (!$pipelineSettings.queue.pool.isHosted) {
        Write-Host "Skipping pipeline ${DefinitionId}: Not a Microsoft-hosted pipeline"
        return
    }
    $vmImage = $pipelineSettings.process.target.agentSpecification.identifier
    if (!$vmImage) {
        Write-Host "Skipping pipeline ${DefinitionId}: Image not defined, not a classic / UI pipeline"
        return
    }
    Write-Host "Pipeline $DefinitionId is using '$vmImage'"

    # Set pipeline level image definition
    if ($vmImage -eq $DeprecatedImage) {
        Write-Host "Updating pipeline $DefinitionId to '$ReplaceWithImage'..."
        $pipelineSettings.process.target.agentSpecification.identifier = $ReplaceWithImage
    }

    # Set job level image definitions
    foreach ($job in $pipelineSettings.process.phases) {
        if ($job.target.agentSpecification.identifier -eq $DeprecatedImage) {
            "Updating pipeline {0} job '{1}' to '{2}'..." -f $DefinitionId, $job.name, $ReplaceWithImage | Write-Host
            Write-Host "Updating pipeline $DefinitionId to '$ReplaceWithImage'..."
            $pipelineSettings.process.target.agentSpecification.identifier = $ReplaceWithImage
            $job.target.agentSpecification.identifier = $ReplaceWithImage
        }
    }

    # Perform update
    $pipelineSettings | ConvertTo-Json -Depth 7 | Invoke-RestMethod -Headers $requestHeaders -Method 'Put' -Uri $itemApi | Write-Debug
    Write-Host "Pipeline $DefinitionId updated to '$($pipelineSettings.process.target.agentSpecification.identifier)'"

}

function Update-Project(
    [parameter(Mandatory=$true)][string]$DeprecatedImage,
    [parameter(Mandatory=$true)][string]$OrganizationUrl,
    [parameter(Mandatory=$true)][string]$Project,
    [parameter(Mandatory=$true)][string]$ReplaceWithImage,
    [parameter(Mandatory=$true)][string]$Token
)
{   
    "Retrieving up to {3} classic / UI pipelines using '{0}' in {1}/{2}" -f $DeprecatedImage, $OrganizationUrl, $Project, $MaxItems | Write-Host
    Find-Pipelines -DeprecatedImage $DeprecatedImage `
                   -OrganizationUrl $OrganizationUrl -Project $Project `
                   -Token $Token `
                   | Set-Variable pipelinedUsingDeprecatedImages
    
    if (!$pipelinedUsingDeprecatedImages) {
        "No classic / UI pipelines found using '{0}' in {1}/{2}" -f $DeprecatedImage, $OrganizationUrl, $Project | Write-Host
        return
    }
    "{0} pipelines are using {1}" -f $pipelinedUsingDeprecatedImages.Count, $DeprecatedImage
    
    foreach ($pipeline in $pipelinedUsingDeprecatedImages) {
        "Updating pipeline '{0}' ({1}) {2} -> {3}..." -f $pipeline.name, $pipeline.id, $DeprecatedImage, $ReplaceWithImage | Write-Host
        Write-Verbose $pipeline._links.web.href
        Update-Pipeline -DefinitionId $pipeline.id `
                        -DeprecatedImage $DeprecatedImage `
                        -OrganizationUrl $OrganizationUrl -Project $Project `
                        -ReplaceWithImage $ReplaceWithImage `
                        -Token $Token
    }
}

$OrganizationUrl = $OrganizationUrl -replace "/$","" # Strip trailing '/'

if ($Project) {
    Update-Project -DeprecatedImage $DeprecatedImage `
                   -OrganizationUrl $OrganizationUrl -Project $Project `
                   -ReplaceWithImage $ReplaceWithImage `
                   -Token $Token

} else {
    "Retrieving up to {0} projects in {1}" -f $MaxItems, $OrganizationUrl | Write-Host
    List-Projects -OrganizationUrl $OrganizationUrl -Token $Token | Set-Variable projects
    foreach ($proj in $projects.value) {
        $projectNameEncoded = [System.Web.HttpUtility]::UrlPathEncode($proj.name)
        "`nProcessing project {0} ({1}/{2})" -f $proj.name, $OrganizationUrl, $projectNameEncoded | Write-Host
    
        Update-Project -DeprecatedImage $DeprecatedImage `
                       -OrganizationUrl $OrganizationUrl -Project $projectNameEncoded `
                       -ReplaceWithImage $ReplaceWithImage `
                       -Token $Token
    }    
}