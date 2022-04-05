# Virtual Machine Scale Sets 

Azure Virtual Machine Scale Sets (VMSS) allow the creation and management of groups of load balanced virtual machines (VMs). With an Azure VMSS, virtual machine instances be centrally managed as well as autoscale depending on demand or schedule. Azure VMSS can be run with the Azure CLI, PowerShell, Azure Resource Manager templates, and the Azure portal.

This article provides an overview of deploying a VMSS template that will install the CrowdStrike Falcon sensor as the virtual machines scale up. For more information on Virtual Machine Scale Sets, see [Virtual Machine Scale Sets documentation](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/).

## Use cases and samples

This VMSS example utilizes a custom script extension to install the CrowdStrike Falcon sensor. A Custom Script extension is available for both Windows and Linux virtual machines. The Custom Script extension for Linux allows any Bash script to be run on a VM. Custom scripts are useful for designing Azure deployments that require configuration beyond what native Azure tooling can provide. For more information, see [Linux VM Custom Script extension](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux). For Windows, see [Windows VM Custom Script extension](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows)

## Prerequisites

A resource group must exist first. To create one, run the following command changing `myResourceGroup` for the appropriate resource group name and `location` for the appropriate region:

```azurecli
az group create --name myResourceGroup --location eastus
```

### Azure CLI

Azure VM extensions can be run against an existing VMSS with the [az vmss extension set](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/quick-create-cli#deploy-sample-application) command. The following example runs the Custom Script extension against a VM named *myVM* in a resource group named *myResourceGroup*. Replace the example resource group name, VM name, and script to run (https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh) with your own information.

#### VMSS Creation for Linux

1. Create the VMSS with a Linux image:
```azurecli
az vmss create \
  --resource-group myResourceGroup \
  --name myScaleSet \
  --image UbuntuLTS \
  --upgrade-policy-mode manual \
  --admin-username azureuser \
  --generate-ssh-keys
```

2. Install the CrowdStrike Falcon Sensor with a Custom VM Extension:
```azurecli
az vmss extension set \
  --resource-group myResourceGroup \
  --vmss-name myScaleSet \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh"],"commandToExecute": "export FALCON_CLIENT_ID=123456789f1c4a0d9987a45123456789 && export FALCON_CLIENT_SECRET=ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789 && /bin/bash falcon-linux-install.sh"}'
```

#### VMSS Creation for Windows

1. Create the VMSS with a Windows image:
```
az vmss create \
  --resource-group myResourceGroup \
  --name myScaleSet \
  --image WindowsServer \
  --upgrade-policy-mode automatic \
  --admin-username myadmin \
  --admin-password azureuser1234!
```

2. Install the CrowdStrike Falcon Sensor with a Custom VM Extension:
```azurecli
az vmss extension set \
  --resource-group myResourceGroup \
  --vmss-name myScaleSet \
  --name customScriptExtension \
  --publisher Microsoft.Compute \
  --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/powershell/install/falcon_windows_install.ps1"],"commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File falcon_windows_install.ps1 -FalconClientId 123456789f1c4a0d9987a45123456789 -FalconClientSecret ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789"}'
```

### Azure Resource Manager templates

VMSS can be added to an Azure Resource Manager template and executed with the deployment of the template. When you deploy an VMSS with a template, you can create fully configured Azure deployments.

#### VMSS Creation for Linux using an ARM template

Before launching the VMSS for Linux deployment, configure or change any parameters in the template's [parameters.json](https://github.com/CrowdStrike/Cloud-Azure/blob/main/vmss/linux/parameters.json) file.
At a minimum, `adminUsername` and `adminPassword` (if your deployment uses passwords instead of SSH keys) should be changed from the default set parameters in the `parameters.json` file as the username and password are publicly viewable.
`clientId` and `clientSecret` variables should also be set to the properly configured CrowdStrike API keys to ensure that the sensor gets installed on instance creation.
For this example, 10 Ubuntu Linux systems will be deployed using a VMSS that will install the CrowdStrike Falcon sensor when the instances are brought up.
After changes have been made to the template's `parameters.json` file, launch the VMSS template with the following Azure CLI command:

```azurecli
az deployment group create --resource-group myResourceGroup --parameters @parameters.json --template-file template.json
```

The CrowdStrike Falcon sensor will be installed on the Linux VM instances when they are launched as part of the VMSS with a Custom Script Extension which is part of the template.
For more information, see the full [Linux Resource Manager template](https://github.com/CrowdStrike/Cloud-Azure/blob/main/vmss/linux/template.json).

#### VMSS Creation for Windows using an ARM template

Before launching the VMSS for Windows deployment, configure or change any parameters in the template's [parameters.json](https://github.com/CrowdStrike/Cloud-Azure/blob/main/vmss/windows/parameters.json) file.
At a minimum, `adminUsername` and `adminPassword` should be changed from the default set parameters in the `parameters.json` file as the username and password are publicly viewable.
`clientId` and `clientSecret` variables should also be set to the properly configured CrowdStrike API keys to ensure that the sensor gets installed on instance creation.
For this example, 10 Ubuntu Linux systems will be deployed using a VMSS that will install the CrowdStrike Falcon sensor when the instances are brought up.
After changes have been made to the template's `parameters.json` file, launch the VMSS template with the following Azure CLI command:

```azurecli
az deployment group create --resource-group myResourceGroup --parameters @parameters.json --template-file template.json
```

The CrowdStrike Falcon sensor will be installed on the Windows VM instances when they are launched as part of the VMSS with a Custom Script Extension which is part of the template.
For more information, see the full [Windows Resource Manager template](https://github.com/CrowdStrike/Cloud-Azure/blob/main/vmss/windows/template.json).


For more information on creating Resource Manager templates, see [Authoring Azure Resource Manager templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/).
