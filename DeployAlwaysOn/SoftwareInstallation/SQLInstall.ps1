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
else{
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
else{
    Write-Verbose "BackupFile exists"
}
#endregion

#region Create folder

$sess = New-Pssession -ComputerName $SQLVM0 -Credential $cred

$Command = {
    $VerbosePreference = 'Continue'
    if(-not(Test-Path F:\Backups)){
        Write-Verbose "Backup Directory created"
        New-Item 'F:\Backups' -ItemType Directory
    }
    else{
        Write-Verbose "Backup Folder exists"
    }
}

Invoke-Command -Session $sess -ScriptBlock $Command *>&1
#endregion

#region Copy BackupFile

$remotepath = "\\$SQlVm0\F`$\Backups\WideWorldImporters-Full.bak"

if(-not(Test-Path $remotepath )){
Write-Verbose "Copying backup file to SQL Server"
Copy-Item $bak -Destination F:\Backups -ToSession $sess
}
else{
    Write-Verbose "Backup file exists on SQLServer"
}

Remove-PSSession $sess

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
    $CheckAGDb = Get-Dbaagdatabase -sqlinstance $SQlVm0 -Availabilitygroup $AgName -Database WideWorldImporters -SqlCredential $cred -EnableException
Write-Verbose "Checked if the database is on the AG"
}
catch {
    Write-Error "Failed to Check the AG"
    break
}


if (-not($CheckAGDb)) {
    $srv = Connect-DbaInstance -SqlInstance $SQLvm0

    if(($srv.Databases.Name -notcontains 'WideWorldImporters')){
        Write-Verbose " Restoring database"
        Restore-DbaDatabase -SqlInstance $SqlVM0 -Path F:\Backups\WideWorldImporters-Full.bak -SqlCredential $cred
    }
    else{
        Write-Verbose "Database already on $SQLVM0"
    }
    if((Get-DbaDbRecoveryModel -SqlInstance $sqlvm0 -Database WideWorldImporters -SqlCredential $cred).RecoveryModel -eq 'SIMPLE' ){
        Write-Verbose "Set the recovery model to FULL"
        Set-DbaDbRecoveryModel -SqlInstance $sqlvm0 -Database WideWorldImporters -RecoveryModel Full -SqlCredential $cred -Confirm:$false
    }
    else{
        Write-Verbose "Database set to FULL Already"
    }


    Write-Verbose "Backup Database"
    Backup-DbaDatabase -SqlInstance $SqlVM0 -Database WideWorldImporters -BackupDirectory F:\Backups -BackupFileName WWI-Full-AGseed.bak -Type Full -SqlCredential $cred
    Backup-DbaDatabase -SqlInstance $SqlVM0 -Database WideWorldImporters -BackupDirectory F:\Backups -BackupFileName WWI-Log-AGseed.trn -Type Log -SqlCredential $cred
    Write-Verbose "Restore database"
    Restore-DbaDatabase -SqlInstance $sqlvm1 -Path "\\$SQlVm0\SQlBackups\WWI-Full-AGseed.bak","\\$SQlVm0\SQlBackups\WWI-Log-AGseed.trn" -WithReplace -NoRecovery -SqlCredential $cred
    Write-Verbose "Add database to AG"
    $PrimaryPAth = "SQLSERVER:\SQL\$SQLVM0\DEFAULT\AvailabilityGroups\$AGName"
    $SecondaryPAth = "SQLSERVER:\SQL\$SQLVM1\DEFAULT\AvailabilityGroups\$AGName"
    Add-SqlAvailabilityDatabase -Path $PrimaryPAth -Database WideWorldImporters 
    Add-SqlAvailabilityDatabase -Path $secondaryPAth -Database WideWorldImporters  
}
else {
    Write-Verbose "Database already on $agName Availability Group on $sqlvm0"
}
