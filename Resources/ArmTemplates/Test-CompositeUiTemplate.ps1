[CmdletBinding()]
param(
    [switch]$DeployToOwnTenant
)

$Location = "West Europe"

$DeploymentParameters = @{
    TemplateFile          = ".\Resources\ArmTemplates\template.json"
}

if($DeployToOwnTenant.IsPresent) {

    $IsLoggedIn = (Get-AzureRMContext -ErrorAction SilentlyContinue).Account
    if (!$IsLoggedIn) {
        Write-Host "Not logged in"
        Login-AzureRmAccount
    }
    elseif ($($IsLoggedIn.Id.split("@")[1] -eq "citizenazuresfabisgov.onmicrosoft.com") -or $($IsLoggedIn.Id.split("@")[1] -eq "fcsazuresfabisgov.onmicrosoft.com")) {
        throw "Logged in to SFA tenant.  Login to your personal tenant to complete a test deployment."
    }
    
    $DeploymentParameters['TemplateParameterFile'] = ".\Resources\ArmTemplates\test-parameters.json"

    $TemplateParamsObject = Get-Content $DeploymentParameters['TemplateParameterFile'] | ConvertFrom-Json

    $ResourceGroupName = $TemplateParamsObject.parameters.ApimResourceGroup.value
    $ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (!$ResourceGroup) {
        Write-Host "- Creating resource group $ResourceGroupName"
        New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
    }

    $ResourceGroupName = "dfc-my-compositeui-rg"
    $ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (!$ResourceGroup) {
        Write-Host "- Creating resource group $ResourceGroupName"
        New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
    }
    
    $DeploymentParameters['ResourceGroup'] = $ResourceGroupName
    $DeploymentParameters['DeploymentDebugLogLevel'] = "All"
    
    Write-Host "- Deploying template"
    New-AzureRmResourceGroupDeployment @DeploymentParameters

} 
else {

    $DeploymentParameters['TemplateParameterFile'] = ".\Resources\ArmTemplates\parameters.json"

    $ResourceGroupName = "dfc-test-template-rg"

    $DeploymentParameters['ResourceGroup'] = $ResourceGroupName
    $DeploymentParameters['ApimResourceGroup'] = $ResourceGroupName
    $DeploymentParameters['Verbose'] = $true

    Write-Host "- Validating template"
    if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {

        Write-Verbose -Message "Deployment Parameters:"
        $DeploymentParameters

    }
    
    Test-AzureRmResourceGroupDeployment @DeploymentParameters
    
}

