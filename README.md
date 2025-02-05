InfraAsCode Project
===================

This repository contains Infrastructure as Code (IaC) artifacts for deploying and managing an Azure environment.
The project demonstrates how to deploy and monitor various Azure components using ARM templates, Azure CLI,
and PowerShell scripts. It was created as part of an interview project and is shared as a public GitHub repository.

Table of Contents
-----------------
1. Project Overview
2. Prerequisites
3. Project Structure
4. Deployment Instructions
   - Deploying the Infrastructure
   - Running In-VM Scripts
   - Deploying the Dashboard
5. Verification and Monitoring
6. Troubleshooting
7. References

1. Project Overview
-------------------
This project automates the deployment of a small Azure environment that includes:
- Two storage accounts deployed via ARM templates.
- A Windows Virtual Machine deployed via an ARM template.
- A PowerShell script (InVmBlobOps.ps1) that runs inside the VM to create, upload, and copy 100 blobs.
- A custom Azure Monitor dashboard (MyMonitoringDashboard) that displays metrics such as VM CPU usage.

All components are defined using ARM templates, YAML pipelines, and PowerShell scripts. Git is used
to manage version control for these artifacts.

2. Prerequisites
----------------
Before deploying this project, ensure you have:
- An active Azure subscription.
- Azure CLI installed (and logged in using `az login`).
- Git installed to clone and manage the repository.
- PowerShell available for running scripts.

3. Project Structure
--------------------
InfraAsCode/
├── MyArmTemplates/
│   ├── azuredeploy.json               # ARM template for Storage Accounts
│   ├── windows-vm.json                # ARM template for the Windows VM
│   └── windows-vm.parameters.json     # Parameters for the VM deployment
├── dashboards/
│   └── dashboard.json                 # ARM template for the Azure Monitor dashboard
├── DeployAndBlobs.ps1                 # PowerShell script to deploy resources and run blob operations
├── InVmBlobOps.ps1                    # PowerShell script to run inside the VM for blob operations
└── README.txt                         # This file

4. Deployment Instructions
--------------------------
A. Deploying the Infrastructure:
   1. Create a resource group:
      az group create --name MyResourceGroup --location eastus
   2. Deploy Storage Accounts:
      az deployment group create --resource-group MyResourceGroup --template-file .\MyArmTemplates\azuredeploy.json --parameters storageAccountNamePrefix="uniquestorprefix"
   3. Deploy the Windows VM:
      az deployment group create --resource-group MyResourceGroup --template-file .\MyArmTemplates\windows-vm.json --parameters .\MyArmTemplates\windows-vm.parameters.json --parameters vmName="myWinSrvVM" adminUsername="azureuser" adminPassword="P@ssw0rd123!"

B. Running In-VM Scripts:
   Run the DeployAndBlobs.ps1 script to deploy the infrastructure and trigger the in-VM blob operations:
      powershell.exe -ExecutionPolicy Bypass -File "C:\Users\danir\Desktop\InfraAsCode\DeployAndBlobs.ps1" -ResourceGroupName "MyResourceGroup" -AdminPassword "P@ssw0rd123!"

C. Deploying the Dashboard:
   Navigate to the dashboards folder and deploy the dashboard template:
      az deployment group create --resource-group MyResourceGroup --template-file ".\dashboards\dashboard.json" --parameters dashboardName="MyMonitoringDashboard"

5. Verification and Monitoring
------------------------------
- **CLI Verification:**  
  List dashboard resources:
      az resource list --resource-group MyResourceGroup --resource-type "Microsoft.Portal/dashboards" --query "[].{Name:name, Id:id}" -o table

- **Metric Verification:**  
  Query VM metrics:
      az monitor metrics list --resource "/subscriptions/c5e5efcd-2381-4d20-96b4-f29afd8fbaaa/resourceGroups/MyResourceGroup/providers/Microsoft.Compute/virtualMachines/myWinSrvVM" --metric "Percentage CPU" --interval PT1H --aggregation Average

- **Azure Portal Verification:**  
  Open MyMonitoringDashboard under the Dashboards section in the Azure Portal to visually inspect the metric charts.

6. Troubleshooting
------------------
- If a dashboard tile shows "An incomplete query has been provided," check that the query properties
  (resource ID, metric name, aggregation, granularity, filter, etc.) are correctly defined.
- Adjust the dashboard time range using the time picker if no data appears.
- Use the browser’s Developer Tools (F12) to inspect for module load or network errors.
- Compare your dashboard tile configuration with one manually created in the portal for differences.
- Clear browser cache or use an incognito window if browser extensions interfere.

7. References
-------------
- Azure CLI Documentation: https://learn.microsoft.com/cli/azure/monitor/metrics?view=azure-cli-latest
- Create and Manage Azure Dashboards: https://learn.microsoft.com/azure/azure-portal/azure-portal-dashboards
- ARM Template Deployment Guide: https://learn.microsoft.com/azure/azure-resource-manager/templates/

---

This README explains the project, how to deploy it, and how to verify its functionality. Customize it as needed before sharing it with your interview team.
 
