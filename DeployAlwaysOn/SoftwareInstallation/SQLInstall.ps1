Param($DomainAdminPassword)
$VerbosePreference = 'Continue'
$Username = 'THEBEARD\EnterpriseAdmin'

$agName = 'SQLClusterAG'
$SqlVM0 = 'sql0'
$SqlVM1 = 'sql1'

$Password = $DomainAdminPassword | ConvertTo-SecureString -AsPlainText  -Force 
$cred = New-Object System.Management.Automation.PSCredential $Username, $Password

#region SqlServer Module

if (-not (Get-module sqlserver -ListAvailable)) {
    Write-Verbose "installing sqlserver module"
    Install-module SqlServer -Scope CurrentUser -Force
}
else {
    Write-Verbose "SQLServer module exists"
}
$VerbosePreference = 'SilentlyContinue'
Import-Module SqlServer 
Import-Module SmbShare

#endregion
$VerbosePreference = 'Continue'
#region downlaod sql backupfile
$bak = $env:TEMP + '/WideWorldImporters-Full.bak' 

if (-not(Test-Path $bak )) {
    Write-Verbose "Downloading WWI backup file"
    $dbbakURL = 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak'

    [Net.ServicePointManager]::SecurityProtocol = 
    [Net.SecurityProtocolType]::Tls12 -bor `
        [Net.SecurityProtocolType]::Tls11 -bor `
        [Net.SecurityProtocolType]::Tls

    (New-Object System.Net.WebClient).DownloadFile($dbbakURL, $bak)
}
else {
    Write-Verbose "BackupFile exists"
}
#endregion

#region Create folder

$sess = New-Pssession -ComputerName $SQLVM0 -Credential $cred
$sess1 = New-Pssession -ComputerName $SQLVM1 -Credential $cred

$Command = {
    $VerbosePreference = 'Continue'
    if (-not(Test-Path F:\Backups)) {
        Write-Verbose "Backup Directory created"
        New-Item 'F:\Backups' -ItemType Directory
    }
    else {
        Write-Verbose "Backup Folder exists"
    }
}

Invoke-Command -Session $sess -ScriptBlock $Command *>&1
Invoke-Command -Session $sess1 -ScriptBlock $Command *>&1
#endregion

#region Copy BackupFile

$Testpath = Invoke-Command -Session $sess -ScriptBlock {Test-Path F:\Backups\WideWorldImporters-Full.bak} *>&1

if ($Testpath -eq $false) {
    Write-Verbose "Copying backup file to SQL Server"
    Copy-Item $bak -Destination F:\Backups -ToSession $sess
}
elseif ($Testpath -eq $true) {
    Write-Verbose "Backup file exists on SQLServer"
}
else {
    Write-Error "Something went wrong with TestPath"
    Break
}

try {
    Write-Verbose "Removing backup files"
    Invoke-Command -Session $sess -ScriptBlock {Get-ChildItem -Path F:\Backups -Filter *AGSeed* | Remove-Item -Force}
}
catch {
    Write-Warning "Failed to remove backup files"
}


## Copy dbatools module onto SQL Server because of stupid WinRM errors with VSTS

try {
    Write-Verbose "Copying dbatools moduel to $SQLVM0 and $SQLVM1"
    Copy-Item -Path $ENV:USERPROFILE\Documents\WindowsPowerShell\Modules\dbatools\* -Recurse -Destination 'C:\Program Files\WindowsPowerShell\Modules\dbatools' -Container -ToSession $sess -Force
    Copy-Item -Path $ENV:USERPROFILE\Documents\WindowsPowerShell\Modules\dbatools\* -Recurse -Destination 'C:\Program Files\WindowsPowerShell\Modules\dbatools' -Container -ToSession $sess1 -Force
}
catch {
    $_
    Write-Error "Failed to copy module to $SQLvm0 and or $SQLVM1"
}


Remove-PSSession $sess
Remove-PSSession $sess1

#endregion

#region create share
$ServiceAccount = (Get-DbaSqlService -ComputerName $SqlVm0 -Credential $cred).Where{$Psitem.ServiceName -eq 'MSSQLSERVER'}.StartName

$Cim = New-CimSession -ComputerName $SqlVm0 -Credential $cred
if (-Not ( Get-SmbShare -CimSession $cim -Name SQLBackups -ErrorAction SilentlyContinue)) {
    Write-Verbose "Creating Backup Share"
    New-SmbShare -Name SQLBackups -Path 'F:\Backups' -FullAccess $ServiceAccount -CimSession $cim 
}
else {
    Write-Verbose "Backup Share already exists"
}
Remove-CimSession $Cim
#endregion

#region Restore database ontSQL Servers


try {
    Write-Verbose "Checking if the database is on the AG"
    $CheckAGDb = Invoke-Command -ComputerName $sqlvm0 -Credential $cred -ScriptBlock {Get-Dbaagdatabase -sqlinstance $Using:SQlVm0 -Availabilitygroup $Using:AgName -Database WideWorldImporters}
    Write-Verbose "Checked if the database is on the AG"
}
catch {
    Write-Error "Failed to Check the AG"
    break
}


if (-not($CheckAGDb)) {
    Invoke-Command -ComputerName $sqlvm0 -Credential $cred -ScriptBlock {
        $VerbosePreference = 'Continue'
        $srv = Connect-DbaInstance -SqlInstance $Using:SQLvm0
        Set-DbaSpConfigure -SqlInstance $Using:SQLvm0 -ConfigName DefaultBackupCompression -Value $True        
        Set-DbaSpConfigure -SqlInstance $Using:SQLvm0 -ConfigName RemoteDacConnectionsEnabled -Value $True   
        Set-DbaSpConfigure -SqlInstance $Using:SQLvm0 -ConfigName AdHocDistributedQueriesEnabled -Value $true  

        Set-DbaMaxMemory -SqlInstance $Using:SQLvm0 -MaxMB (Test-DbaMaxMemory -SqlInstance $Using:SQLvm0).RecommendedMb
        if (($srv.Databases.Name -notcontains 'WideWorldImporters')) {
            Write-Verbose " Restoring database on $Using:SQLvm0"
            Restore-DbaDatabase -SqlInstance $Using:SQLvm0 -Path F:\Backups\WideWorldImporters-Full.bak 
        }
        else {
            Write-Verbose "Database already on $Using:SQLvm0"
        }
        if ((Get-DbaDbRecoveryModel -SqlInstance $Using:sqlvm0 -Database WideWorldImporters).RecoveryModel -eq 'SIMPLE' ) {
            Write-Verbose "Set the recovery model to FULL"
            Set-DbaDbRecoveryModel -SqlInstance $Using:sqlvm0 -Database WideWorldImporters -RecoveryModel Full  -Confirm:$false
        }
        else {
            Write-Verbose "Database set to FULL Already"
        }

        Write-Verbose "Backup Database on $Using:SQLvm0"
        Backup-DbaDatabase -SqlInstance $Using:SqlVM0 -Database WideWorldImporters -BackupDirectory F:\Backups -BackupFileName WWI-Full-AGseed.bak -Type Full 
        Backup-DbaDatabase -SqlInstance $Using:SqlVM0 -Database WideWorldImporters -BackupDirectory F:\Backups -BackupFileName WWI-Diff-AGseed.bak -Type Differential
        Backup-DbaDatabase -SqlInstance $Using:SqlVM0 -Database WideWorldImporters -BackupDirectory F:\Backups -BackupFileName WWI-Log-AGseed.trn -Type Log 
    }
    Invoke-Command -ComputerName $SqlVM1 -Credential $cred -ScriptBlock {
        $VerbosePreference = 'Continue'
        Write-Verbose "Restore database on $Using:sqlvm1"
        Set-DbaMaxMemory -SqlInstance $Using:SQLvm1 -MaxMB (Test-DbaMaxMemory -SqlInstance $Using:SQLvm1).RecommendedMb
        Set-DbaSpConfigure -SqlInstance $Using:SQLvm1 -ConfigName DefaultBackupCompression -Value $True
        Set-DbaSpConfigure -SqlInstance $Using:SQLvm1 -ConfigName RemoteDacConnectionsEnabled -Value $True
        Set-DbaSpConfigure -SqlInstance $Using:SQLvm1 -ConfigName AdHocDistributedQueriesEnabled -Value $true

        Restore-DbaDatabase -SqlInstance $Using:sqlvm1 -Path "\\$Using:SQlVm0\SQlBackups\WWI-Full-AGseed.bak", "\\$Using:SQlVm0\SQlBackups\WWI-Diff-AGseed.trn" , "\\$Using:SQlVm0\SQlBackups\WWI-Log-AGseed.trn" -WithReplace -NoRecovery 
    }
    Write-Verbose "Add database to AG"
    $PrimaryPAth = "SQLSERVER:\SQL\$SQLVM0\DEFAULT\AvailabilityGroups\$AGName"
    $SecondaryPAth = "SQLSERVER:\SQL\$SQLVM1\DEFAULT\AvailabilityGroups\$AGName"
    Invoke-Command -ComputerName $sqlvm0 -Credential $cred -ScriptBlock {
        $VerbosePreference = 'Continue'
        Write-Verbose "Add database to AG on $Using:SQLvm0"
        Add-SqlAvailabilityDatabase -Path $Using:PrimaryPAth -Database WideWorldImporters 
    }
    Invoke-Command -ComputerName $sqlvm1 -Credential $cred -ScriptBlock {
        $VerbosePreference = 'Continue'
        Write-Verbose "Add database to AG on $Using:SQLvm1"
        Add-SqlAvailabilityDatabase -Path $Using:secondaryPAth -Database WideWorldImporters  
    }
}

else {
    Write-Verbose "Database already on $agName Availability Group on $sqlvm0"
}

Invoke-Command -ComputerName $sqlvm0 -Credential $cred -ScriptBlock {
    $VerbosePreference = 'Continue'    
    Write-Verbose "Setting Always On Extended Event to auto start and starting on $Using:SQLvm0"
    $xe = (Get-DbaXEStore -SqlInstance $Using:SqlVM0).Sessions['Alwayson_Health']
    $xe.AutoStart = $true
    $xe.Alter()
    if ($xe.Start -eq $false) {
        $xe.Start()
    }
}

Invoke-Command -ComputerName $SqlVM1 -Credential $cred -ScriptBlock {
    $VerbosePreference = 'Continue'
    Write-Verbose "Setting Always On Extended Event to auto start and starting on $Using:SQLvm1"   
    $xe = (Get-DbaXEStore -SqlInstance $Using:SqlVM1).Sessions['Alwayson_Health']
    $xe.AutoStart = $true
    $xe.Alter()
    if ($xe.Start -eq $false) {
        $xe.Start()
    }
}

# Install-Ola and schedule
Invoke-Command -ComputerName $SqlVM0 -Credential $cred -ScriptBlock {
    $VerbosePreference = 'Continue'
    Write-Verbose "Installing Ola Hallengren maintenance solution on $Using:SQLvm0"
    $instance = $Using:SqlVM0 
    Set-Service -Name SQLSERVERAGENT -StartupType Automatic
    Install-DbaWhoIsActive -SqlInstance $instance -Database master
    Install-DbaMaintenanceSolution -SqlInstance $instance -Database master -BackupLocation F:\Backups -CleanupTime 700 -OutputFileDirectory F:\Backups -LogToTable -InstallJobs 
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseBackup - SYSTEM_DATABASES - FULL'  -Schedule daily -FrequencyType Daily -FrequencyInterval Everyday -StartTime 010000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseBackup - USER_DATABASES - DIFF'  -Schedule Weekdays -FrequencyType Weekly -FrequencyInterval Weekdays -StartTime 020000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseBackup - USER_DATABASES - FULL'  -Schedule Sunday -FrequencyType Weekly -FrequencyInterval Sunday -StartTime 020000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseBackup - USER_DATABASES - LOG'  -Schedule '15 Minutes' -FrequencyType Daily -FrequencyInterval EveryDay -FrequencySubdayType Minutes -FrequencySubdayInterval 15 -StartTime 000000 -Force

    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseIntegrityCheck - SYSTEM_DATABASES'  -Schedule Saturday -FrequencyType Weekly -FrequencyInterval Saturday -StartTime 210000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseIntegrityCheck - USER_DATABASES'  -Schedule Saturday -FrequencyType Weekly -FrequencyInterval Saturday -StartTime 220000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'IndexOptimize - USER_DATABASES'  -Schedule Saturday -FrequencyType Weekly -FrequencyInterval Saturday -StartTime 230000 -Force

    New-DbaAgentSchedule -SqlInstance $Instance -Job 'CommandLog Cleanup'  -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'Output File Cleanup'  -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'sp_delete_backuphistory'  -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'sp_purge_jobhistory'  -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
    (Get-DbaAgentJob -SqlInstance $instance).Start()
}
Invoke-Command -ComputerName $SqlVM1 -Credential $cred -ScriptBlock {
    $VerbosePreference = 'Continue'
    Write-Verbose "Installing Ola Hallengren maintenance solution on $Using:SQLvm1"   
    $instance = $Using:SqlVM1
    Set-Service -Name SQLSERVERAGENT -StartupType Automatic
    Install-DbaMaintenanceSolution -SqlInstance $instance -Database master -BackupLocation F:\Backups -CleanupTime 700 -OutputFileDirectory F:\Backups -LogToTable -InstallJobs 
    Install-DbaWhoIsActive -SqlInstance $instance -Database master

    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseBackup - SYSTEM_DATABASES - FULL'  -Schedule daily -FrequencyType Daily -FrequencyInterval Everyday -StartTime 010000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseBackup - USER_DATABASES - DIFF'  -Schedule Weekdays -FrequencyType Weekly -FrequencyInterval Weekdays -StartTime 020000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseBackup - USER_DATABASES - FULL'  -Schedule Sunday -FrequencyType Weekly -FrequencyInterval Sunday -StartTime 020000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseBackup - USER_DATABASES - LOG'  -Schedule '15 Minutes' -FrequencyType Daily -FrequencyInterval EveryDay -FrequencySubdayType Minutes -FrequencySubdayInterval 15 -StartTime 000000 -Force

    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseIntegrityCheck - SYSTEM_DATABASES'  -Schedule Saturday -FrequencyType Weekly -FrequencyInterval Saturday -StartTime 210000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'DatabaseIntegrityCheck - USER_DATABASES'  -Schedule Saturday -FrequencyType Weekly -FrequencyInterval Saturday -StartTime 220000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'IndexOptimize - USER_DATABASES'  -Schedule Saturday -FrequencyType Weekly -FrequencyInterval Saturday -StartTime 230000 -Force

    New-DbaAgentSchedule -SqlInstance $Instance -Job 'CommandLog Cleanup'  -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'Output File Cleanup'  -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'sp_delete_backuphistory'  -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
    New-DbaAgentSchedule -SqlInstance $Instance -Job 'sp_purge_jobhistory'  -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
    (Get-DbaAgentJob -SqlInstance $instance).Start()
}

## Install Alerts
$SQL = C:\Windows\Temp\AlertsInstall.ps1 -Instance $SQLvm0 -accountname DBATeam -EmailAddress DBAAlerts@thebeard.local -displayname DBATeam -replytoaddress TheDBATeam@TheBeard.Local -mailserver mail.TheBeard.Local -profilename DBATeam -Operatorname 'The DBA Team' -OperatorEmail TheDBATeam@TheBeard.Local -ScriptOnly
Invoke-Command -ComputerName $SqlVM0 -Credential $cred -ScriptBlock {
    $VerbosePreference = 'Continue'
    Write-Verbose "Installing SQL ALerts on  $Using:SQLvm0" 
    Invoke-Sqlcmd -ServerInstance $Using:SQLvm0 -Database msdb -Query $Using:SQL
}

$SQL = C:\Windows\Temp\AlertsInstall.ps1 -Instance $SQLvm1 -accountname DBATeam -EmailAddress DBAAlerts@thebeard.local -displayname DBATeam -replytoaddress TheDBATeam@TheBeard.Local -mailserver mail.TheBeard.Local -profilename DBATeam -Operatorname 'The DBA Team' -OperatorEmail TheDBATeam@TheBeard.Local -ScriptOnly
Invoke-Command -ComputerName $SQLvm1 -Credential $cred -ScriptBlock {
    $VerbosePreference = 'Continue'
    Write-Verbose "Installing SQL ALerts on  $Using:SQLvm1" 
    Invoke-Sqlcmd -ServerInstance $Using:SQLvm1 -Database msdb -Query $Using:SQL
}



Write-Verbose "FiINISHED THE THING"
