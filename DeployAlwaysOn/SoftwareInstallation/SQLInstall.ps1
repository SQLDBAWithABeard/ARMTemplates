$agName = 'SQLClusterAG'
$SqlVM0 = 'sql0'
$SqlVM1 = 'sql1'

#region SqlServer Module

if (-not (Get-module sqlserver -ListAvailable)) {
    Write-Output "installing sqlserver module"
    Install-module SqlServer -Scope CurrentUser
}
else{
    Write-Output "SQLServer module exists"
}

Import-Module SqlServer

#endregion

#region downlaod sql backupfile
$bak = $env:TEMP + '/WideWorldImporters-Full.bak' 

if (-not(Test-Path $bak )) {
    Write-Output "Downloading WWI backup file"
    $dbbakURL = 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak'

    [Net.ServicePointManager]::SecurityProtocol = 
    [Net.SecurityProtocolType]::Tls12 -bor `
        [Net.SecurityProtocolType]::Tls11 -bor `
        [Net.SecurityProtocolType]::Tls

    (New-Object System.Net.WebClient).DownloadFile($dbbakURL, $bak)
}
else{
    Write-Output "BackupFile exists"
}
#endregion

#region Create folder

$sess = New-Pssession -ComputerName $SQLVM0

$Command = {
    if(-not(Test-Path F:\Backups)){
        Write-Output "Backup Directory created"
        New-Item 'F:\Backups' -ItemType Directory
    }
    else{
        Write-Output "Backup Folder exists"
    }
}

Invoke-Command -Session $sess -ScriptBlock $Command 
#endregion

#region Copy BackupFile

$remotepath = "\\$SQlVm0\F`$\Backups\WideWorldImporters-Full.bak"

if(-not(Test-Path $remotepath )){
Write-Output "Copying backup file to SQL Server"
Copy-Item $bak -Destination F:\Backups -ToSession $sess
}
else{
    Write-Output "Backup file exists on SQLServer"
}

Remove-PSSession $sess

#endregion

#region create share
$ServiceAccount = (Get-DbaSqlService -ComputerName $SqlVm0).Where{$Psitem.ServiceName -eq 'MSSQLSERVER'}.StartName

$Cim = New-CimSession -ComputerName $SqlVm0
if (-Not ( Get-SmbShare -CimSession $cim -Name SQLBackups -ErrorAction SilentlyContinue)) {
    Write-Output "Creating Backup Share"
    New-SmbShare -Name SQLBackups -Path 'F:\Backups' -FullAccess $ServiceAccount -CimSession $cim 
}
else {
    Write-Output "Backup Share already exists"
}
Remove-CimSession $Cim
#endregion

#region Restore database ontSQL Servers

if (-not(Get-Dbaagdatabase -sqlinstance $SQlVm0 -Availabilitygroup $AgName -Database WideWorldImporters)) {
    $srv = Connect-DbaInstance -SqlInstance $SQLvm0

    if(($srv.Databases.Name -notcontains 'WideWorldImporters')){
        Write-Output " Restoring database"
        Restore-DbaDatabase -SqlInstance $SqlVM0 -Path F:\Backups\WideWorldImporters-Full.bak
    }
    else{
        Write-Output "Database already on $SQLVM0"
    }
    if((Get-DbaDbRecoveryModel -SqlInstance $sqlvm0 -Database WideWorldImporters).RecoveryModel -eq 'SIMPLE'){
        Write-Output "Set the recovery model to FULL"
        Set-DbaDbRecoveryModel -SqlInstance $sqlvm0 -Database WideWorldImporters -RecoveryModel Full -Confirm:$false
    }
    else{
        Write-Output "Database set to FULL Already"
    }


    Write-Output "Backup Database"
    Backup-DbaDatabase -SqlInstance $SqlVM0 -Database WideWorldImporters -BackupDirectory F:\Backups -BackupFileName WWI-Full-AGseed.bak -Type Full
    Backup-DbaDatabase -SqlInstance $SqlVM0 -Database WideWorldImporters -BackupDirectory F:\Backups -BackupFileName WWI-Log-AGseed.trn -Type Log
    Write-Output "Restore database"
    Restore-DbaDatabase -SqlInstance $sqlvm1 -Path "\\$SQlVm0\SQlBackups\WWI-Full-AGseed.bak","\\$SQlVm0\SQlBackups\WWI-Log-AGseed.trn" -WithReplace -NoRecovery
    Write-Output "Add database to AG"
    $PrimaryPAth = "SQLSERVER:\SQL\$SQLVM0\DEFAULT\AvailabilityGroups\$AGName"
    $SecondaryPAth = "SQLSERVER:\SQL\$SQLVM1\DEFAULT\AvailabilityGroups\$AGName"
    Add-SqlAvailabilityDatabase -Path $PrimaryPAth -Database WideWorldImporters  
    Add-SqlAvailabilityDatabase -Path $secondaryPAth -Database WideWorldImporters  
}
else {
    Write-Output "Database already on $agName Availability Group on $sqlvm0"
}
