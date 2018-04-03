$SubnetId = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $env:ResourceGroupName).Where{$_.DeploymentName -like '*Core-DC-Network-template*' -and $_.ProvisioningState -eq 'Succeeded'}[0].Outputs.Get_Item("vMsubnetID").Value
$JumpBoxDNS = (Get-AzureRmPublicIpAddress -ResourceGroupName $env:ResourceGroupName -Name JumpBox-nic-ip).DnsSettings.Fqdn
$JumpBoxStorageAccount = (Get-AzureRmStorageAccount -ResourceGroupName $Resourcegroup).Where{$_.StorageAccountName -like '*vmdiag'}[0].StorageAccountName

Write-Host "##vso[task.setvariable variable=SubNetID]$Subnetid"
Write-Host "##vso[task.setvariable variable=JumpBoxDNS]$JumpBoxDNS"
Write-Host "##vso[task.setvariable variable=JumpBoxStorageAccount]$JumpBoxStorageAccount"
