Param($DomainAdminPassword)
$Username = 'EnterpriseAdmin'

$Password = $DomainAdminPassword | ConvertTo-SecureString -AsPlainText  -Force 
$cred = New-Object System.Management.Automation.PSCredential $Username, $Password
$so = New-PsSessionOption -SkipCACheck -SkipCNCheck
$session = New-PSSession -ComputerName beardjumpbox.westeurope.cloudapp.azure.com -Credential $cred -UseSSL -SessionOption $so
$Url = $ENV:JumpBoxSoftwareInstallscript
Invoke-Command -Session $session -ScriptBlock {(New-Object System.Net.WebClient).DownloadFile($Using:Url, 'C:\Windows\Temp\SoftwareInstall.ps1')}