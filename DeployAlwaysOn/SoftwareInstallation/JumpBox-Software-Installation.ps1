$VerbosePreference = 'Continue'
#Install Chocolatey
if (!(Test-Path "$($env:ProgramData)\chocolatey\choco.exe")) {
    Write-Verbose "Installing Chocolatey"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
else {
    Write-Verbose "Chocolatey installed"
}

$Programmes = (Get-Package -ProviderName programs).Name 
$Programmes += (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName
$Programmes += (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName

#Install software
Write-Verbose "Installing programmes"

$Installs =  @()
$Installs += [PSCustomObject]@{Prog ='Microsoft Visual Studio Code';Install = 'visualstudiocode'}
$Installs += [PSCustomObject]@{Prog ='Notepad++ (64-bit x64)';Install = 'notepadplusplus'}
$Installs += [PSCustomObject]@{Prog ='Microsoft SQL Server Management Studio - 17.6';Install = 'sql-server-management-studio'}
$Installs += [PSCustomObject]@{Prog ='SQL Operations Studio';Install = 'sql-operations-studio'}
$Installs += [PSCustomObject]@{Prog ='Google Chrome';Install = 'googlechrome'}
$Installs += [PSCustomObject]@{Prog ='Git version 2.16.3';Install = 'git'}
$Installs += [PSCustomObject]@{Prog ='Microsoft Power BI Desktop (x64)';Install = 'powerbi'}


$Installs.ForEach{
    if($Programmes -contains $psitem.Prog){
        Write-Verbose "$($Psitem.Prog) already installed"
    }
    else {
        Write-Verbose "Installing $($Psitem.Prog)"
        choco install $psitem.Install --yes
    }
}

choco install vscode-powershell --yes
choco install vscode-mssql --yes
choco install vscode-gitlens --yes

# Install vscodeextensions module and extensions

if([version](Get-PackageProvider -Name nuGet).Version -le [version]2.8.5.201){
    Write-Verbose "Installing Nuget"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

if(-not(Get-Module vscodeextensions -ListAvailable)){
    Write-Verbose "Installing VS Code Extension"
    Install-Module vscodeextensions -Scope CurrentUser -Force
}

$VSCodeExtensions = 'material-theme-pack', 'bracket-pair-colorizer', 'powershell','mssql', 'gitlens'
$VSCodeExtensions.ForEach{
    if(Get-VsCodeExtension $PSitem){
        Write-Verbose "VS Code Extension $psitem already installed"
    }
    else{
        Write-Verbose "Installing VS Code Extension $psitem "
        Install-VSCodeExtension -ExtensionName $PSitem
    }
}

# do this first as it is a pain - it will error if it is already there and then can be updated below
Install-Module Pester -Scope CurrentUser -SkipPublisherCheck -Force -ErrorAction SilentlyContinue

$Modules = 'dbatools', 'PSFramework', 'dbachecks', 'Pester'

$Modules.ForEach{
    if (-not (Get-Module $Psitem -ListAvailable -ErrorAction SilentlyContinue)) {
        Write-Verbose "Installing Module $Psitem"
        Install-Module $Psitem -Scope CurrentUser -Force
    }
    else {
        Write-Verbose "Mosule $psitem already exists"
    }
}


