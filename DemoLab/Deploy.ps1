Login-AzureRmAccount

$ResourcegroupName = 'DemoRG'
$location = 'westeurope'
New-AzureRmResourceGroup -Name ExampleResourceGroup -Location $location

## Deploys overarching template from Git
$newAzureRmResourceGroupDeploymentSplat = @{
    ResourceGroupName = $ResourcegroupName
    TemplateFile = 'Git:\ARMTemplates\DemoLab\azuredeploy.json'
    Name = $ResourcegroupName
}

New-AzureRmResourceGroupDeployment @newAzureRmResourceGroupDeploymentSplat

