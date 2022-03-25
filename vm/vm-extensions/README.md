# Virtual machine extensions and features for Linux

Azure virtual machine (VM) extensions are small applications that provide post-deployment configuration and automation tasks on Azure VMs. A VM extension can be used. Azure VM extensions can be run with the Azure CLI, PowerShell, Azure Resource Manager templates, and the Azure portal. Extensions can be bundled with a new VM deployment, or run against any existing system.

This article provides an overview of a VM extension for installing the CrowdStrike Falcon sensor.

## Use cases and samples

This CrowdStrike extension utilises a custom script extension. A Custom Script extension is available for both Windows and Linux virtual machines. The Custom Script extension for Linux allows any Bash script to be run on a VM. Custom scripts are useful for designing Azure deployments that require configuration beyond what native Azure tooling can provide. For more information, see [Linux VM Custom Script extension](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux).

## Prerequisites

To handle the extension on the VM, you need the Azure Linux Agent installed.

### Azure VM agent

The Azure VM agent manages interactions between an Azure VM and the Azure fabric controller. The VM agent is responsible for many functional aspects of deploying and managing Azure VMs, including running VM extensions. The Azure VM agent is preinstalled on Azure Marketplace images, and can be installed manually on supported operating systems. The Azure VM Agent for Linux is known as the Linux agent.

For information on supported operating systems and installation instructions, see [Azure virtual machine agent](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/agent-linux).

#### Supported agent versions

In order to provide the best possible experience, there are minimum versions of the agent. For more information, see [this article](https://support.microsoft.com/en-us/help/4049215/extensions-and-virtual-machine-agent-minimum-version-support).


## Run VM extensions

Azure VM extensions run on existing VMs, which is useful when you need to make configuration changes or recover connectivity on an already deployed VM. VM extensions can also be bundled with Azure Resource Manager template deployments. By using extensions with Resource Manager templates, Azure VMs can be deployed and configured without post-deployment intervention.

The following methods can be used to run an extension against an existing VM.

### Azure CLI

Azure VM extensions can be run against an existing VM with the [az vm extension set](https://docs.microsoft.com/en-us/cli/azure/vm/extension?view=azure-cli-latest#az-vm-extension-set) command. The following example runs the Custom Script extension against a VM named *myVM* in a resource group named *myResourceGroup*. Replace the example resource group name, VM name, and script to run (https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh) with your own information.

```azurecli
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh"],"commandToExecute": "export FALCON_CLIENT_ID=123456789f1c4a0d9987a45123456789 && export FALCON_CLIENT_SECRET=ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789 && /bin/bash falcon-linux-install.sh"}'
```

When the extension runs correctly, the output is similar to the following example:

```json
{
  "autoUpgradeMinorVersion": true,
  "enableAutomaticUpgrade": null,
  "forceUpdateTag": null,
  "id": "/subscriptions/12345678-abcd-abcd-abcd-abcdefg12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM/extensions/CustomScript",
  "instanceView": null,
  "location": "myLocation",
  "name": "CustomScript",
  "protectedSettings": null,
  "provisioningState": "Succeeded",
  "publisher": "Microsoft.Azure.Extensions",
  "resourceGroup": "myResourceGroup",
  "settings": {},
  "suppressFailures": null,
  "tags": null,
  "type": "Microsoft.Compute/virtualMachines/extensions",
  "typeHandlerVersion": "2.1",
  "typePropertiesType": "CustomScript"
}
```

### Azure Resource Manager templates

VM extensions can be added to an Azure Resource Manager template and executed with the deployment of the template. When you deploy an extension with a template, you can create fully configured Azure deployments.

```azurecli
az deployment group create \
  --name ExampleDeployment \
  --resource-group ExampleGroup \
  --template-file ./linux.json
```

For more information, see the full [Resource Manager template](https://github.com/CrowdStrike/Cloud-Azure/blob/main/vm-extensions/arm/linux/linux.json).

```json
    {
      "type": "Microsoft.Compute/virtualMachines/extensions",
      "name": "[concat(parameters('vmName'),'/installCrowdStrike')]",
      "apiVersion": "2019-12-01",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Compute/virtualMachines/', parameters('vmName'))]"
      ],
      "properties": {
        "publisher": "Microsoft.Azure.Extensions",
        "type": "CustomScript",
        "typeHandlerVersion": "2.0",
        "autoUpgradeMinorVersion": true,
        "protectedSettings": {
          "fileUris": [
            "https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh"
          ],

          "commandToExecute": "[concat('export FALCON_CID=', parameters('cid'), ' && export FALCON_CLIENT_ID=', parameters('clientId'), ' && export FALCON_CLIENT_SECRET=', parameters('clientSecret'), ' && /bin/bash falcon-linux-install.sh')]"
        }
      }
    }
```

For more information on creating Resource Manager templates, see [Authoring Azure Resource Manager templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/).

### Terraform

Terraform supports [Azure virtual machine extensions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension)

Example
```terraform
resource "azurerm_virtual_machine_extension" "myterraformvm" {
  name = "hostname"
  virtual_machine_id = azurerm_linux_virtual_machine.myterraformvm.id
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.0"
  protected_settings = <<PROTECTED
  {
    "fileUris": [
          "https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh"
        ],
    "commandToExecute": "export FALCON_CID=${var.cid} && export FALCON_CLIENT_ID=${var.client_id} && export FALCON_CLIENT_SECRET=${var.client_secret} && export FALCON_CLOUD=${var.falcon_cloud} && /bin/bash falcon-linux-install.sh"
  }
  PROTECTED

  tags = {
    environment = "Production"
  }
}
```

A working [terraform example](terraform) is provided.
