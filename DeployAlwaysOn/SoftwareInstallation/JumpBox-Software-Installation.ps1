#Install Chocolatey

Write-Output "Installing Chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))


#Install software
Write-Output "Installing programmes"
choco install googlechrome --yes
choco install visualstudiocode --yes
choco install vscode-powershell --yes
choco install vscode-mssql --yes
choco install vscode-gitlens --yes
choco install notepadplusplus --yes
choco install sql-server-management-studio  --yes
choco install sql-operations-studio --yes
choco install git --yes
choco install powerbi --yes

# Install vscodeextensions module and extensions

Install-Module vscodeextensions -Scope CurrentUser

Install-VSCodeExtension -ExtensionName material-theme-pack 
Install-VSCodeExtension -ExtensionName bracket-pair-colorizer 

$Modules = 'dbatools','PSFramework','dbachecks'

$Modules.ForEach{
    if(-not (Get-Module $Psitem -ErrorAction SilentlyContinue)){
        Write-Output "Installing Module $Psitem"
        Install-Module $Psitem -Scope CurrentUser
    }
    else{
        Write-Output "Updating Module $Psitem"
        Update-Module $Psitem
    }
}
