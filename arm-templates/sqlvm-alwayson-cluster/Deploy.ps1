## Login-AzureRmAccount

$ResourcegroupName = 'BeardSQLAD011'
$location = 'westeurope'
New-AzureRmResourceGroup -Name $ResourcegroupName -Location $location

## Deploys overarching template from Git
$newAzureRmResourceGroupDeploymentSplat = @{
    ResourceGroupName = $ResourcegroupName
    TemplateFile = 'C:\Users\mrrob\OneDrive\Documents\GitHub\ARMTemplates\arm-templates\sqlvm-alwayson-cluster\azuredeploy.json'
    TemplateParameterFile = 'C:\Users\mrrob\OneDrive\Documents\GitHub\ARMTemplates\arm-templates\sqlvm-alwayson-cluster\azuredeploy.parameters.json'
    Name = $ResourcegroupName
}

New-AzureRmResourceGroupDeployment @newAzureRmResourceGroupDeploymentSplat

