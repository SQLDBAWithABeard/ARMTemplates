$VerbosePreference = 'Continue'
#Install Chocolatey
if (!(Test-Path "$($env:ProgramData)\chocolatey\choco.exe")) {
Write-Verbose "Installing Chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}else{
    Write-Verbose "Chocolatey installed"
}


#Install software
Write-Verbose "Installing programmes"
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

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module vscodeextensions -Scope CurrentUser -Force

Install-VSCodeExtension -ExtensionName material-theme-pack 
Install-VSCodeExtension -ExtensionName bracket-pair-colorizer 

# do this first as it is a pain - it will error if it is already there and then can be updated below
Install-Module Pester -Scope CurrentUser -SkipPublisherCheck -Force -ErrorAction SilentlyContinue

$Modules = 'dbatools','PSFramework','dbachecks','Pester'

$Modules.ForEach{
    if(-not (Get-Module $Psitem -ListAvailable -ErrorAction SilentlyContinue)){
        Write-Verbose "Installing Module $Psitem"
        Install-Module $Psitem -Scope CurrentUser -Force
    }
    else{
        Write-Verbose "Updating Module $Psitem"
        Update-Module $Psitem
    }
}


