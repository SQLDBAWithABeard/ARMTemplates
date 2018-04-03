Describe "Testing Programmes and modules are installed on machine" -Tags Programmes, Install {
    Context "Programmes" {
        BeforeAll {
            $Programmes = (Get-Package -ProviderName programs).Name 
            $Programmes += (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName
            $Programmes += (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName
        }
        $Expected = 'Microsoft Visual Studio Code', 'Notepad++ (64-bit x64)','Microsoft SQL Server Management Studio - 17.6','SQL Operations Studio','Google Chrome','Git version 2.16.3','Microsoft Power BI Desktop (x64)'
        $Expected.ForEach{
            It "Should have $_" {
                $Programmes | Should -Contain $_ -Because "We want $($_) installed"
            }
        }
    }
    Context "Modules"{
        $modules = 'dbatools','dbachecks','PsFramework','vscodeextensions'
        $modules.ForEach{
            It "Should have $_ Module installed" {
                Get-Module $_ -ListAvailable | Should -Not -BeNullOrEmpty -Because "We want the module $($_) available"
            }
        }
    }
    Context "VS Code Extensions" {
        if(Get-Module vscodeextensions -ListAvailable){
            $Extensions = 'bracket-pair-colorizer','gitlens','material-theme-pack','mssql','PowerShell'
            $Extensions.ForEach{
                It "Should have $_ VS Code Extension" {
                    (Get-VSCodeExtension).ExtensionName | Should -Contain $_ -Because "We want to have $($_) VS Code Extension"
                }
            }
        }
        else{
            It "Should have VS Code Extensions Module" {
                $true | Should -Be $False -Because "We need the vscodeextension module to test for vs code extensions"
            }
        }
    }
}