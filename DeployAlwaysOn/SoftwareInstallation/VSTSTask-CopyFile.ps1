Param($DomainAdminPassword)
$VerbosePreference = 'Continue'
$Username = 'EnterpriseAdmin'

Enable-WSManCredSSP -Role server -Force
Enable-WSManCredSSP -Role client -DelegateComputer beardjumpbox.westeurope.cloudapp.azure.com -Force -Verbose
Set-Item wsman:localhost\client\trustedhosts -value * -Force

$Password = $DomainAdminPassword | ConvertTo-SecureString -AsPlainText  -Force 
$cred = New-Object System.Management.Automation.PSCredential $Username, $Password

Write-Verbose "Creating PSSession"
$so = New-PsSessionOption -SkipCACheck -SkipCNCheck 
$session = New-PSSession -ComputerName beardjumpbox.westeurope.cloudapp.azure.com -Credential $cred -UseSSL -SessionOption $so
$Url = $ENV:JumpBoxSoftwareInstallscript
$PesterUrl = $ENV:PesterProgramme
$SQLInstallUrl = $ENV:SQLInstallFile

Write-Verbose "Downloading the files"
$ICOuput = Invoke-Command -Session $session -ScriptBlock {
    $VerbosePreference = 'Continue'
    (New-Object System.Net.WebClient).DownloadFile($Using:Url, 'C:\Windows\Temp\SoftwareInstall.ps1')
    (New-Object System.Net.WebClient).DownloadFile($Using:PesterUrl, 'C:\Windows\Temp\Programmes.Tests.ps1')
    (New-Object System.Net.WebClient).DownloadFile($Using:SQLInstallUrl, 'C:\Windows\Temp\SQLInstall.ps1')

} *>&1
Write-Verbose "File Output is - $ICOutput"

Write-Verbose "Running Software Install Script"
$ICOuput = Invoke-Command -Session $session -ScriptBlock{C:\Windows\Temp\SoftwareInstall.ps1} *>&1
Write-Verbose "Software Install Output is -$ICOutput"

Write-Verbose "Running Pester"
Invoke-Command -Session $session -ScriptBlock{Invoke-Pester C:\Windows\Temp\ -OutputFile C:\Windows\Temp\PesterTestResults.xml -OutputFormat NUnitXml} *>&1
Copy-Item -FromSession $session C:\windows\Temp\PesterTestResults.xml -Destination $ENV:SYSTEM_DEFAULTWORKINGDIRECTORY

$session = New-PSSession -ComputerName beardjumpbox.westeurope.cloudapp.azure.com -Credential $cred -UseSSL -SessionOption $so -Authentication Credssp

Write-Verbose "Running SQL Install Script"
$ICOuput = Invoke-Command -Session $session -ScriptBlock{C:\Windows\Temp\SQLInstall.ps1} *>&1
Write-Verbose "SQL Install Output is -$ICOutput"