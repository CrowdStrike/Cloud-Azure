# Virtual machine extensions and features for Linux

Azure virtual machine (VM) extensions are small applications that provide post-deployment configuration and automation tasks on Azure VMs. A VM extension can be used. Azure VM extensions can be run with the Azure CLI, PowerShell, Azure Resource Manager templates, and the Azure portal. Extensions can be bundled with a new VM deployment, or run against any existing system.

This article provides an overview of a VM extension for installing the CrowdStrike Falcon sensor.

## Use cases and samples

This CrowdStrike extension utilises a custom script extension. A Custom Script extension is available for both Windows and Linux virtual machines. The Custom Script extension for Linux allows any Bash script to be run on a VM. Custom scripts are useful for designing Azure deployments that require configuration beyond what native Azure tooling can provide. For more information, see [Linux VM Custom Script extension](custom-script-linux.md).

## Prerequisites

To handle the extension on the VM, you need the Azure Linux Agent installed. 

### Azure VM agent

The Azure VM agent manages interactions between an Azure VM and the Azure fabric controller. The VM agent is responsible for many functional aspects of deploying and managing Azure VMs, including running VM extensions. The Azure VM agent is preinstalled on Azure Marketplace images, and can be installed manually on supported operating systems. The Azure VM Agent for Linux is known as the Linux agent.

For information on supported operating systems and installation instructions, see [Azure virtual machine agent](agent-linux.md).

#### Supported agent versions

In order to provide the best possible experience, there are minimum versions of the agent. For more information, see [this article](https://support.microsoft.com/en-us/help/4049215/extensions-and-virtual-machine-agent-minimum-version-support).


## Run VM extensions

Azure VM extensions run on existing VMs, which is useful when you need to make configuration changes or recover connectivity on an already deployed VM. VM extensions can also be bundled with Azure Resource Manager template deployments. By using extensions with Resource Manager templates, Azure VMs can be deployed and configured without post-deployment intervention.

The following methods can be used to run an extension against an existing VM.

### Azure CLI

Azure VM extensions can be run against an existing VM with the [az vm extension set](/cli/azure/vm/extension#az-vm-extension-set) command. The following example runs the Custom Script extension against a VM named *myVM* in a resource group named *myResourceGroup*. Replace the example resource group name, VM name and script to run (https:\//raw.githubusercontent.com/me/project/hello.sh) with your own information. 

```azurecli
az vm extension set `
  --resource-group myResourceGroup `
  --vm-name myVM `
  --name customScript `
  --publisher Microsoft.Azure.Extensions `
  --settings '{"fileUris": ["https://raw.githubusercontent.com/CrowdStrike/Cloud-Azure/master/vm-extensions/scripts/start-falcon-bootstrap.sh"],"commandToExecute": "./start-falcon-bootstrap.sh --cid=AAACCCDDDEEEFFFD6983B8BD6BBBB-E2 --client_id=123456789f1c4a0d9987a45123456789 --client_secret=ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789"}'
```

When the extension runs correctly, the output is similar to the following example:

```bash
info:    Executing command vm extension set
+ Looking up the VM "myVM"
+ Installing extension "CustomScript", VM: "mvVM"
info:    vm extension set command OK
```

### Azure Resource Manager templates

VM extensions can be added to an Azure Resource Manager template and executed with the deployment of the template. When you deploy an extension with a template, you can create fully configured Azure deployments. 

For more information, see the full [Resource Manager template](https://https://github.com/CrowdStrike/Cloud-Azure/blob/master/vm-extensions/arm/linux/Ubuntu-18).

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
        "settings": {
          "fileUris": [
            "https://raw.githubusercontent.com/CrowdStrike/Cloud-Azure/master/vm-extensions/scripts/start-falcon-bootstrap.sh"
          ],
          
          "commandToExecute": "[concat('bash start-falcon-bootstrap.sh --cid=', parameters('cid'), ' --client_id=', parameters('clientId'), ' --client_secret=', parameters('clientSecret'))]"
        }
      }
    }
```

For more information on creating Resource Manager templates, see [Authoring Azure Resource Manager templates](../windows/template-description.md#extensions).
