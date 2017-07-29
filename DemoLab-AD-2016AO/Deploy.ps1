## Login-AzureRmAccount

$ResourcegroupName = 'DemoLabWithAORG'
$location = 'westeurope'
New-AzureRmResourceGroup -Name $ResourcegroupName -Location $location

## Deploys overarching template from Git
$newAzureRmResourceGroupDeploymentSplat = @{
    ResourceGroupName = $ResourcegroupName
    TemplateFile = 'Git:\ARMTemplates\DemoLab-AD-2016AO\azuredeploy.json' 
    Name = $ResourcegroupName
}

New-AzureRmResourceGroupDeployment @newAzureRmResourceGroupDeploymentSplat

