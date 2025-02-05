<#
.SYNOPSIS
    Runs on the VM to create a container (if needed), generate and upload 100 blobs to Storage Account A,
    and copy those blobs to Storage Account B.
.DESCRIPTION
    1) Installs Azure CLI if it’s not present.
    2) Uses the full path to Azure CLI to ensure commands are found.
    3) Creates the container in Storage Account A.
    4) Generates and uploads 100 files to that container.
    5) Creates the container in Storage Account B.
    6) Initiates a batch copy of the blobs from A to B.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountAName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountBName,

    [Parameter(Mandatory = $true)]
    [string]$StorageKeyA,

    [Parameter(Mandatory = $true)]
    [string]$StorageKeyB,

    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "mytestcontainer"
)

Write-Host "==== In-VM script started... ===="

# Check if Azure CLI is installed; if not, install it.
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Azure CLI not found. Installing..."
    Invoke-WebRequest -Uri "https://aka.ms/installazurecliwindows" -OutFile "AzureCLI.msi"
    Start-Process msiexec.exe -Wait -ArgumentList "/I AzureCLI.msi /quiet"
    Remove-Item .\AzureCLI.msi -Force
    Write-Host "Azure CLI installed."
    # Update the PATH environment variable for the current session.
    $env:PATH += ";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
} else {
    Write-Host "Azure CLI is already installed."
}

# Set the full path to the Azure CLI command (az.cmd).
$azPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
if (-not (Test-Path $azPath)) {
    # If not found in the (x86) path, try the alternative.
    $azPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
}

Write-Host "Using Azure CLI at:" $azPath

Write-Host "Creating container '$ContainerName' in Storage Account A: $StorageAccountAName..."
& $azPath storage container create --name $ContainerName --account-name $StorageAccountAName --account-key $StorageKeyA --output none

Write-Host "Generating and uploading 100 files to container '$ContainerName' in A..."
For ($i = 1; $i -le 100; $i++) {
    $fileName = "file$i.txt"
    "This is file #$i, created at $(Get-Date)" | Out-File -FilePath $fileName
    & $azPath storage blob upload --container-name $ContainerName --account-name $StorageAccountAName --account-key $StorageKeyA --name $fileName --file $fileName --output none
    Remove-Item $fileName -Force
}

Write-Host "Ensuring container '$ContainerName' exists in Storage Account B: $StorageAccountBName..."
& $azPath storage container create --name $ContainerName --account-name $StorageAccountBName --account-key $StorageKeyB --output none

Write-Host "Copying 100 blobs from A to B..."
& $azPath storage blob copy start-batch --source-container $ContainerName --source-account-name $StorageAccountAName --source-account-key $StorageKeyA --destination-container $ContainerName --account-name $StorageAccountBName --account-key $StorageKeyB --output none

Write-Host "Blob copy initiated. Done in-VM script."
