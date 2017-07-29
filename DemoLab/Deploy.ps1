Login-AzureRmAccount

$ResourcegroupName = 'DemoRG'
New-AzureRmResourceGroup -Name ExampleResourceGroup -Location ukwest

## Deploys overarching template from Git
$newAzureRmResourceGroupDeploymentSplat = @{
    ResourceGroupName = $ResourcegroupName
    TemplateFile = 'Git:\ARMTemplates\DemoLab\azuredeploy.json'
    Name = $ResourcegroupName
}

New-AzureRmResourceGroupDeployment @newAzureRmResourceGroupDeploymentSplat

