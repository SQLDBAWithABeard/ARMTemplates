Param($DomainAdminPassword)
$Username = 'EnterpriseAdmin'

$Password = $DomainAdminPassword | ConvertTo-SecureString -AsPlainText  -Force 
$cred = New-Object System.Management.Automation.PSCredential $Username, $Password
Write-Output "Creating PSSession"
$so = New-PsSessionOption -SkipCACheck -SkipCNCheck
$session = New-PSSession -ComputerName beardjumpbox.westeurope.cloudapp.azure.com -Credential $cred -UseSSL -SessionOption $so
$Url = $ENV:JumpBoxSoftwareInstallscript
Write-Output "Downloading File"
$ICOuput = Invoke-Command -Session $session -ScriptBlock {(New-Object System.Net.WebClient).DownloadFile($Using:Url, 'C:\Windows\Temp\SoftwareInstall.ps1')}
Write-Output $ICOutput
Write-Output "Running Install Script"
$ICOuput = Invoke-Command -Session $session -ScriptBlock{ 'C:\Windows\Temp\SoftwareInstall.ps1'}
Write-Output $ICOutput