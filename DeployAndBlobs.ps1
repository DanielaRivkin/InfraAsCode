<#
.SYNOPSIS
  Deploys Storage Accounts and a Windows VM using ARM templates, then invokes an in‑VM script 
  to create, upload, and copy 100 blobs from Storage Account A to Storage Account B.
.DESCRIPTION
  Steps:
  1) Create or verify the Resource Group.
  2) Deploy Storage Accounts using an ARM template.
  3) Deploy a Windows VM using an ARM template.
  4) Retrieve the keys for both storage accounts.
  5) Run a run-command on the VM that executes InVmBlobOps.ps1.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$StoragePrefix = "uniquestorprefix",  # Must be <= 22 chars, all lowercase

    [Parameter(Mandatory = $false)]
    [string]$VmName = "myWinSrvVM",

    [Parameter(Mandatory = $false)]
    [string]$AdminUsername = "azureuser",

    [Parameter(Mandatory = $true)]
    [string]$AdminPassword,  # e.g., "P@ssw0rd123!"

    [Parameter(Mandatory = $false)]
    [string]$TemplateFileStorage = ".\MyArmTemplates\azuredeploy.json",

    [Parameter(Mandatory = $false)]
    [string]$TemplateFileVM = ".\MyArmTemplates\windows-vm.json",

    [Parameter(Mandatory = $false)]
    [string]$TemplateParametersVM = ".\MyArmTemplates\windows-vm.parameters.json",

    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "mytestcontainer",

    [Parameter(Mandatory = $false)]
    [string]$InVmScriptPath = ".\InVmBlobOps.ps1"
)

Write-Host "=== 1. Create or Check Resource Group ==="
az group create --name $ResourceGroupName --location $Location --output none

Write-Host "=== 2. Deploy Storage Accounts (ARM Template) ==="
az deployment group create --name DeployStorageAccounts --resource-group $ResourceGroupName --template-file $TemplateFileStorage --parameters storageAccountNamePrefix=$StoragePrefix --output none

# Retrieve the storage account names from the deployment output
$storageOutputs = az deployment group show --resource-group $ResourceGroupName --name DeployStorageAccounts --query properties.outputs --output json | ConvertFrom-Json

$StorageAccountAName = $storageOutputs.storageAccount1Name.value
$StorageAccountBName = $storageOutputs.storageAccount2Name.value

Write-Host "StorageAccountAName =" $StorageAccountAName
Write-Host "StorageAccountBName =" $StorageAccountBName

Write-Host "=== 3. Deploy Windows VM (ARM Template) ==="
az deployment group create --name DeployWinVM --resource-group $ResourceGroupName --template-file $TemplateFileVM --parameters $TemplateParametersVM --parameters vmName=$VmName adminUsername=$AdminUsername adminPassword=$AdminPassword --output none

$vmOutputs = az deployment group show --resource-group $ResourceGroupName --name DeployWinVM --query properties.outputs --output json | ConvertFrom-Json
$VmFqdn = $vmOutputs.vmPublicIP.value
Write-Host "The VM Public FQDN is:" $VmFqdn
Write-Host "=== VM Deployment Completed ==="

Write-Host "=== 4. Retrieve Storage Account Keys ==="
$stgKeyA = az storage account keys list --resource-group $ResourceGroupName --account-name $StorageAccountAName --query "[0].value" -o tsv
$stgKeyB = az storage account keys list --resource-group $ResourceGroupName --account-name $StorageAccountBName --query "[0].value" -o tsv

Write-Host "=== 5. Run Script INSIDE the VM to create, upload, and copy blobs ==="
az vm run-command invoke --command-id RunPowerShellScript --name $VmName --resource-group $ResourceGroupName --scripts "@$InVmScriptPath" --parameters "StorageAccountAName=$StorageAccountAName" "StorageAccountBName=$StorageAccountBName" "StorageKeyA=$stgKeyA" "StorageKeyB=$stgKeyB" "ContainerName=$ContainerName"

Write-Host "=== All Done! ==="
Write-Host "Verify the 100 blobs in Storage Account B. VM FQDN:" $VmFqdn
