Param($DomainAdminPassword)
$Username = 'EnterpriseAdmin'

$Password = $DomainAdminPassword | ConvertTo-SecureString -AsPlainText  -Force 
$cred = New-Object System.Management.Automation.PSCredential $Username, $Password
Write-Output "Creating PSSession"
$so = New-PsSessionOption -SkipCACheck -SkipCNCheck
$session = New-PSSession -ComputerName beardjumpbox.westeurope.cloudapp.azure.com -Credential $cred -UseSSL -SessionOption $so
$Url = $ENV:JumpBoxSoftwareInstallscript
$PesterUrl = $ENV:PesterProgramme
$SQLInstallUrl = $ENV:SQLInstallFile
Write-Output "Downloading the files"
$ICOuput = Invoke-Command -Session $session -ScriptBlock {
    (New-Object System.Net.WebClient).DownloadFile($Using:Url, 'C:\Windows\Temp\SoftwareInstall.ps1')
    (New-Object System.Net.WebClient).DownloadFile($Using:PesterUrl, 'C:\Windows\Temp\Programmes.Tests.ps1')
    (New-Object System.Net.WebClient).DownloadFile($Using:SQLInstallUrl, 'C:\Windows\Temp\SQLInstall.ps1')
}
Write-Output $ICOutput
Write-Output "Running Install Script"
$ICOuput = Invoke-Command -Session $session -ScriptBlock{C:\Windows\Temp\SoftwareInstall.ps1}
Write-Output $ICOutput

Write-Output "Running Pester"
Invoke-Command -Session $session -ScriptBlock{Invoke-Pester C:\Windows\Temp\ -OutputFile C:\Windows\Temp\PesterTestResults.xml -OutputFormat NUnitXml} 
Copy-Item -FromSession $session C:\windows\Temp\PesterTestResults.xml -Destination $ENV:SYSTEM_DEFAULTWORKINGDIRECTORY

Write-Output "Running Install Script"
#$ICOuput = Invoke-Command -Session $session -ScriptBlock{C:\Windows\Temp\SQLInstall.ps1}
Write-Output $ICOutput