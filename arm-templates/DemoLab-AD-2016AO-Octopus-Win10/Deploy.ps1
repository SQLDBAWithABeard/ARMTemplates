## Login-AzureRmAccount

$ResourcegroupName = 'DLM-Lab-AO-Octo-RG'
$location = 'westeurope'
New-AzureRmResourceGroup -Name $ResourcegroupName -Location $location

## Deploys overarching template from Git
$newAzureRmResourceGroupDeploymentSplat = @{
    ResourceGroupName = $ResourcegroupName
    TemplateFile = 'Git:\ARMTemplates\DemoLab-AD-2016AO-Octopus-Win10\azuredeploy.json' 
    Name = $ResourcegroupName
}

New-AzureRmResourceGroupDeployment @newAzureRmResourceGroupDeploymentSplat

