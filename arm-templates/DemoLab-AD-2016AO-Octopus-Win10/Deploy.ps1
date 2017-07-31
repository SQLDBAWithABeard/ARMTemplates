## Login-AzureRmAccount

$ResourcegroupName = 'DLM-Lab-AO-Octo-RG'
$location = 'westeurope'
New-AzureRmResourceGroup -Name $ResourcegroupName -Location $location

## Deploys overarching template from Git
$newAzureRmResourceGroupDeploymentSplat = @{
    ResourceGroupName = $ResourcegroupName
    TemplateFile = 'Git:\ARMTemplates\arm-templates\DemoLab-AD-2016AO-Octopus-Win10\azuredeploy.json' 
    Name = 'DeployLab'
}

New-AzureRmResourceGroupDeployment @newAzureRmResourceGroupDeploymentSplat

