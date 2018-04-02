# Install HansenAzurePS
try {
    Write-Output "Installing HansenAzurePS"
    Install-Module HansenAzurePS -Scope CurrentUser -Force 
    Write-Output "Installed HansenAzurePS"

}
catch {
    Write-Error "Failed to Install HansenAzurePS $($_)"
}

$ErrorActionPreference = 'Stop'

# Set location to module home path in artifacts directory
try {
    Set-Location $(Build.SourcesDirectory)
    Get-ChildItem
}
catch {
    Write-Error "Failed to set location"
}

## Set the file paths to variables

$DomainBuildJson = Get-GitHubRawPath -File .\DeployAlwaysOn\Core-DC-Network-template.json
$DomainBuildParams = Get-GitHubRawPath -File ".\DeployAlwaysOn\Core -DC-Network-parametersFile.json"
$SQLBuildJson = Get-GitHubRawPath -File .\DeployAlwaysOn\AlwaysOn-template.json
$SQLBuildParams = Get-GitHubRawPath -File .\DeployAlwaysOn\AlwaysOn-parameters.json
$LinuxSQLBuild = Get-GitHubRawPath -File .\DeployAlwaysOn\LinuxSQL-template.json
$LinuxSQLBuildParams = Get-GitHubRawPath -File .\DeployAlwaysOn\LinuxSQL-parameters.json
$SQLInstall = Get-GitHubRawPath -File .\DeployAlwaysOn\SoftwareInstallation\SQLInstall.ps1

Write-Host "##vso[task.setvariable variable=DomainBuildJson]$DomainBuildJson"
Write-Host "##vso[task.setvariable variable=DomainBuildParams]$DomainBuildParams"
Write-Host "##vso[task.setvariable variable=SQLBuildJson]$SQLBuildJson"
Write-Host "##vso[task.setvariable variable=SQLBuildParams]$SQLBuildParams"
Write-Host "##vso[task.setvariable variable=Linuxbuildjson]$LinuxSQLBuild"
Write-Host "##vso[task.setvariable variable=linuxbuildparams]$LinuxSQLBuildParams"
Write-Host "##vso[task.setvariable variable=sqlinstallscript]$SQLInstall"

## Check we have the variables ready for another process

Write-Output "Domain Build File Path = $ENV:DomainBuildJson"
Write-Output "Domain Build Params File Path = $ENV:DomainBuildParams"
Write-Output "SQL Build File Path = $ENV:SQLBuildJson"
Write-Output "SQL Build Params File Path = $ENV:SQLBuildParams"
Write-Output "Linux SQL Build File Path = $ENV:Linuxbuildjson"
Write-Output "Linux SQL Build Params File Path = $ENV:linuxbuildparams"
Write-Output "SQL Install File Path = $ENV:sqlinstallscript"
