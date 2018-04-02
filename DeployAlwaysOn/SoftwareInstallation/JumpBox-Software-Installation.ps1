  #Install PackageProviders
  
  Install-PackageProvider nuget -Force
  Install-PackageProvider Chocolatey -Force


        #Install packages

        Install-Package vscode.portable -Source Chocolatey -Force
        Install-Package vscode-powershell -Source Chocolatey -Force
        Install-Package vscode-mssql -Source Chocolatey -Force
        Install-Package vscode-gitlens -Source Chocolatey -Force
        # Install-Package vscode-docker -Source Chocolatey -Force
        Install-Package -Name GoogleChrome -Source Chocolatey -Force
        Install-Package -Name notepadplusplus -Source Chocolatey -Force



        # Install vscodeextensions module and extensions

        Install-Module vscodeextensions -Scope CurrentUser

        Install-VSCodeExtension -ExtensionName material-theme-pack 
        Install-VSCodeExtension -ExtensionName bracket-pair-colorizer 



    }