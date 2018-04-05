Param($DomainAdminPassword)
$VerbosePreference = 'Continue'
$Username = 'THEBEARD\EnterpriseAdmin'

$Password = $DomainAdminPassword | ConvertTo-SecureString -AsPlainText  -Force 
$cred = New-Object System.Management.Automation.PSCredential $Username, $Password

Write-Verbose "Creating PSSession"
$so = New-PsSessionOption -SkipCACheck -SkipCNCheck 
$session = New-PSSession -ComputerName beardjumpbox.westeurope.cloudapp.azure.com -Credential $cred -UseSSL -SessionOption $so
$Url = $ENV:JumpBoxSoftwareInstallscript
$PesterUrl = $ENV:PesterProgramme
$SQLInstallUrl = $ENV:SQLInstallFile
$PesterConfigURL = $ENV:dbachecksconfig

Write-Verbose "Downloading the files"
$ICOuput = Invoke-Command -Session $session -ScriptBlock {
    $VerbosePreference = 'Continue'
    $AlertsScript = 'https://raw.githubusercontent.com/SQLDBAWithABeard/SQLScripts/master/PowerShell/SetUpSQLAlerts.ps1'
    (New-Object System.Net.WebClient).DownloadFile($Using:Url, 'C:\Windows\Temp\SoftwareInstall.ps1')
    (New-Object System.Net.WebClient).DownloadFile($Using:PesterUrl, 'C:\Windows\Temp\Programmes.Tests.ps1')
    (New-Object System.Net.WebClient).DownloadFile($Using:SQLInstallUrl, 'C:\Windows\Temp\SQLInstall.ps1')
    (New-Object System.Net.WebClient).DownloadFile($AlertsScript, 'C:\Windows\Temp\AlertsInstall.ps1')
    (New-Object System.Net.WebClient).DownloadFile($Using:PesterConfigUrl, 'C:\Windows\Temp\FirstBuild.json')

} *>&1
Write-Verbose "File Output is - $ICOutput"

Write-Verbose "Running Software Install Script"
Invoke-Command -Session $session -ScriptBlock{C:\Windows\Temp\SoftwareInstall.ps1} *>&1
Write-Verbose "Software Install Output is -$ICOutput"

Write-Verbose "Running Pester"
Invoke-Command -Session $session -ScriptBlock{Invoke-Pester C:\Windows\Temp\ -OutputFile C:\Windows\Temp\PesterTestResults.xml -OutputFormat NUnitXml} *>&1
Copy-Item -FromSession $session C:\windows\Temp\PesterTestResults.xml -Destination $ENV:SYSTEM_DEFAULTWORKINGDIRECTORY


Write-Verbose "Running SQL Install Script"
$ICOuput = Invoke-Command -Session $session -ScriptBlock{C:\Windows\Temp\SQLInstall.ps1 -DomainAdminPassword $Using:DomainAdminPassword } *>&1
Write-Verbose "SQL Install Output is -$ICOutput"

Install-Module Invoke-CommandAs -Scope CurrentUser -Force

$scriptBlock = {
Import-Dbcconfig -Path C:\Windows\Temp\FirstBuild.json
Invoke-DbcCheck -AllChecks -Show Fails -PassThru | Update-DbcPowerBiDataSource -Path C:\windows\temp\dbachecksPesterTestResults.xml
}
Invoke-CommandAs -Session $session -ScriptBlock $scriptBlock
Copy-Item -FromSession $session C:\windows\temp\dbachecksPesterTestResults.xml -Destination $ENV:SYSTEM_DEFAULTWORKINGDIRECTORY

